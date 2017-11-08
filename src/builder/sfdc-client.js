var fs = require("fs");
var util = require("util");
var htmlEncode = require("escape-html");
var soap = require("soap");
var gutil = require("gulp-util");
var fsutil = require("./fs-util.js");

function newSFDCClient(org, outDir, srcDir) {
    var client = new SFDCClient(org, outDir, srcDir);
    client.login();
    return client;
}

function SFDCClient(org, outDir, srcDir) {
    this.outDir = outDir;
    this.srcDir = srcDir;
    this.org = org;
    this.loadingClients;
    this.loggingIn;
    this.deploying;
    this.metadataClient;
    this.partnerClient;
    this.session;
    this.deployCheckCount;
    this.deploymentId;
    this.loggedIn = false;
    this._load();
}

/**
 * Loads the appropriate WSDLs and should only be called once.
 */
SFDCClient.prototype._load = function() {
    var self = this;

    if (self.loadingClients) {
        console.log("Already loading/loaded SFDC Deploy clients");
        return self.loadingClients;
    }

    self.loadingClients = Promise.all([
        // Load the Metadata WSDL
        new Promise(function(resolve, reject) {
            soap.createClient((self.org.environment == "test" ? "builder/metadata-test-wsdl.xml" : "builder/metadata-wsdl.xml"), function(err, client) {
                self.metadataSOAPClient = client;
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        }),

        // Load the Partner WSDL
        new Promise(function(resolve, reject) {
            soap.createClient((self.org.environment == "test" ? "builder/partner-test-wsdl.xml" : "builder/partner-wsdl.xml"), function(err, client) {
                self.partnerClient = client;
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        }),

    ]);

    return self.loadingClients;
}

/**
 * Attempts to log in to Salesforce using the provided credentials. If
 * successful, this will also properly initialize the partner and metadata SOAP clients.
 */
SFDCClient.prototype.login = function() {
    var self = this;

    if (self.loggedIn) {
        return Promise.resolve();
    } else if (self.loggingIn) {
        return self.loggingIn;
    }

    self.loggedIn = false;
    self.loggingIn = new Promise(function(resolve, reject) {
        self._makeLoginClient()

            .then(function(client) {
                return self._newSession(client);
            }, function(err) {
                reject(err);
            })

            .then(function(session) {
                self.session = session;
                return self._makePartnerClient();
            }, function(err) {
                reject(err);
            })

            .then(function(client) {
                self.partnerClient = client;
                return self._makeMetadataClient();
            }, function(err) {
                reject(err);
            })

            .then(function(client) {
                self.metadataClient = client;
                self.loggedIn = true;
                self.loggingIn = null;
                resolve();
            }, function(err) {
                reject(err);
            });
    });
    return self.loggingIn;
};

/**
 * Creates a Partner Login client.
 */
SFDCClient.prototype._makeLoginClient = function() {
    var self = this;
    return new Promise(function(resolve, reject) {
        soap.createClient( (self.org.environment == "test" ? "builder/partner-test-wsdl.xml" : "builder/partner-wsdl.xml"), function(err, client) {
            if (err) {
                reject(err);
            } else {
                resolve(client);
            }
        });
    });
};

/**
 * Gets a new session object.
 */
SFDCClient.prototype._newSession = function(client) {
    var self = this;
    return new Promise(function(resolve, reject) {
        // TODO: Work properly with sandboxes.
        var loginArgs = {
            username: self.org.username,
            password: self.org.password
        };
        client.login(loginArgs, function(err, result) {
            if (err) {
                reject(err);
            } else {
                // TODO: Handle result failures.
                resolve(result.result);
            }
        });
    });
};

/**
 * Creates a partner SOAP client based on the internal session object.
 */
SFDCClient.prototype._makePartnerClient = function() {
    var self = this;
    return new Promise(function(resolve, reject) {
        if (!self.session) {
            reject("Must log in before initializing client");
            return;
        } else {
            var opts = {
                endpoint: self.session.serverUrl
            };
            soap.createClient((self.org.environment == "test" ? "builder/partner-test-wsdl.xml" : "builder/partner-wsdl.xml"), opts, function(err, client) {
                if (err) {
                    reject(err);
                } else {
                    client.addSoapHeader({
                        SessionHeader: {sessionId: self.session.sessionId}
                    }, null, "tns");
                    resolve(client);
                }
            });
        }
    });
}

/**
 * Creates a metadata SOAP client based on the internal session object.
 */
SFDCClient.prototype._makeMetadataClient = function() {
    var self = this;
    return new Promise(function(resolve, reject) {
        if (!self.session) {
            reject("Must log in before initializing client");
            return;
        } else {
            var opts = {
                endpoint: self.session.metadataServerUrl
            };
            soap.createClient( (self.org.environment == "test" ? "builder/metadata-test-wsdl.xml" : "builder/metadata-wsdl.xml"), opts, function(err, client) {
                if (err) {
                    reject(err);
                } else {
                    client.addSoapHeader({
                        SessionHeader: {sessionId: self.session.sessionId}
                    }, null, "tns");
                    resolve(client);
                }
            });
        }
    });
}

/**
 * Returns a little bit of information about the session in string format. This
 * is useful for including in log lines.
 */
SFDCClient.prototype.cuteSession = function() {
    if (this.session) {
        return "(" + this.org.username + ")";
    } else {
        return "(" + this.org.username + " ?)";
    }
}

/**
 * Deploys the BINARY package data.
 */
SFDCClient.prototype.deploy = function(packageData) {
    var self = this;
    return new Promise(function(resolve, reject) {
        var deployment = new _MetadataDeployment(self);
        deployment.deploy(packageData, self.makeDeployOpts(), function(result) {
            gutil.log(self.cuteSession() + " " + result.details);
            resolve(result);
        }, function(err) {
            //gutil.log(self.cuteSession() + " " + err.details);
            reject(err);
        }, function(progress) {
            gutil.log(self.cuteSession() + " " + progress.details);
        });
    });
};

SFDCClient.prototype.makeDeployOpts = function() {
    var opts = {
        allowMissingFiles: false,
        autoUpdatePackage: false,
        checkOnly: (this.org.mode !== "deploy"),
        ignoreWarnings: false,
        performRetrieve: false,
        purgeOnDelete: false,
        rollbackOnError: true,
        runTests: [],
        singlePackage: true,
        testLevel: (this.org.mode == "run-tests") ? "RunLocalTests" : "NoTestRun"
    };
    return opts;
}

/**
 * Helper class for managing a single deployment. This wraps up a lot of the
 * helper code that goes along with checking deployment into a single location.
 */
function _MetadataDeployment(client) {
    this.client = client;
    this.deploymentId = null;
    this.checkCount = null;
    this.resolve = null;
    this.reject = null;
    this.progress = null;
    this.locked = false;
}

_MetadataDeployment.prototype.deploy = function(packageBinary, opts, resolve, reject, progress) {
    var self = this;

    if (!self.client.session || !self.client.metadataClient) {
        gutil.log("Must be logged in before starting a deployment " + self.cuteSession());
        return Promise.reject("Must be logged in before starting a deployment");
    } else if (self.locked) {
        gutil.log("This deployment has already started");
        return Promise.reject("This deployment has already started");
    }

    self.locked = true;
    self.resolve = resolve;
    self.reject = reject;
    self.progress = progress;
    gutil.log(self.client.cuteSession() + " Starting deployment...");

    var deployArgs = {
        ZipFile: (new Buffer(packageBinary)).toString("base64"),
        DeployOptions: opts
    };

    gutil.log(self.client.cuteSession() + " Uploading package...");
    self.client.metadataClient.deploy(deployArgs, function(err, result) {
        if (err) {
            gutil.log(self.client.cuteSession() + " Deploy failed ", err);
            self.reject(err);
        } else {
            gutil.log(self.client.cuteSession() + " Package uploaded. Job Id: " + result.result.id);
            result = result.result;
            self.checkCount = 0;
            self.deploymentId = result.id;
            self._checkDeployment();
        }
    });
};

_MetadataDeployment.prototype._checkDeployment = function() {
    var self = this;

    var checkArgs = {
        asyncProcessId: self.deploymentId,
        includeDetails: false
    };
    self.client.metadataClient.checkDeployStatus(checkArgs, function(err, result) {
        if (err) {
            self.reject(err);
        } else {
            result = result.result;
            self.progress(self._makeProgressObject(result));
            if (result.done) {
                self._handleFinalStatus();
            } else {
                setTimeout(function() {
                    self._checkDeployment()
                }, self._getDelay());
                self.checkCount += 1;
            }
        }
    });
};

_MetadataDeployment.prototype._handleFinalStatus = function() {
    var self = this;

    var checkArgs = {
        asyncProcessId: self.deploymentId,
        includeDetails: true
    };
    self.client.metadataClient.checkDeployStatus(checkArgs, function(err, result) {
        if (err) {
            self.reject(err);
        } else {
            result = result.result;
            result.errors = [];
            result.hasErrors = false;

            fs.writeFileSync(
                self.client.outDir + "/" + self.client.org.username + "-results.json",
                JSON.stringify(result, null, 4)
            );

            var testWriter = new _TestResultWriter(self.client, result);
            testWriter.execute()
                .catch(function(err) {
                    gutil.log("Unable to write test results. " + err);
                    return Promise.resolve();
                })
                .then(function() {
                    if (result.success) {
                        self.resolve(self._makeProgressObject(result));
                    } else {

                        if (result.details && result.details.componentFailures) {
                            result.errors.concat(result.details.componentFailures);
                            fs.writeFileSync(
                                self.client.outDir + "/" + self.client.org.username + "-failures.json",
                                JSON.stringify(result.details.componentFailures, null, 4)
                            );
                        }

                        if (result.details && result.details.runTestResult && result.details.runTestResult.failures) {
                            result.errors.concat(result.details.runTestResult.failures);
                            fs.writeFileSync(
                                self.client.outDir + "/" + self.client.org.username + "-test-failures.json",
                                JSON.stringify(result.details.runTestResult.failures, null, 4)
                            );
                        }

                        result.hasErrors = result.errors.length > 0;
                        self.reject(self._makeProgressObject(result));
                    }
                });
        }
    });
};

_MetadataDeployment.prototype._makeProgressObject = function(result) {

    var statusDetails = "";

    if (result.stateDetail) {
        statusDetails += result.stateDetail;
    } else {
        statusDetails += result.status;
    }

    // Update current progress
    if (result.numberTestsTotal) {
        statusDetails += " (" + result.numberTestsCompleted + "/" + result.numberTestsTotal;
        if (result.numberTestErrors) {
            statusDetails += ", " + result.numberTestErrors + " errors";
        }
        statusDetails += ")";
    } else if (result.numberComponentsTotal) {
        statusDetails += " (" + result.numberComponentsDeployed + "/" + result.numberComponentsTotal;
        if (result.numberComponentErrors) {
            statusDetails += ", " + result.numberComponentErrors + " errors";
        }
        statusDetails += ")";
    }

    // Add details about component failures
    if (result.details && result.details.componentFailures) {

        result.details.componentFailures.forEach(function(failure, i) {
            if (i < 50) {
                statusDetails += "\n* Error " + (i + 1) + " \"" + failure.fileName + "\"" +
                        ((failure.lineNumber) ? (" Line " + failure.lineNumber) : "") +
                        ": " + failure.problem;
            }
        });

        if (result.details.componentFailures.length > 50) {
            statusDetails += "\n* Additional failures can be found in -failures.json file.";
        }
    }

    // Add details about test failures.
    if (result.details && result.details.runTestResult && result.details.runTestResult.failures) {

        result.details.runTestResult.failures.forEach(function(failure, i) {
            if (i < 50) {
                statusDetails += "\n* Test Failure " + (i + 1) + " \"" + failure.name + "." + failure.methodName + "\"" +
                        ": " + failure.message + "\n" + 
                        failure.stackTrace.replace(/\n/g, "\n    ");
            }
        });

        if (result.details.runTestResult.failures.length > 50) {
            statusDetails += "\n* Additional failures can be found in -test-failures.json file.";
        }
    }

    return {"details": statusDetails};
}

_MetadataDeployment.prototype._getDelay = function() {
    if (!this.checkCount || this.checkCount < 5) {
        return 1000;
    } else if (this.checkCount < 20) {
        return 3000;
    } else {
        return 10000;
    }
}

function _TestResultWriter(client, result) {
    this.srcDir = client.srcDir;
    this.outDir = client.outDir;
    this.result = result;
    this.testResult = null;
    this.coverageDir = client.outDir + "/coverage-" + client.org.username;
    this.coverageDirUri = "coverage-" + encodeURIComponent(client.org.username);
    this.indexFilename = client.outDir + "/test-results-" + client.org.username + ".html";

    if (result && result.details && result.details.runTestResult) {
        this.testResult = result.details.runTestResult;
    }

    this._compareCoverage = function(a, b) {
        if (a.numLocationsNotCovered == b.numLocationsNotCovered) {
            return b.numLocations - a.numLocations;
        } else {
            return b.numLocationsNotCovered - a.numLocationsNotCovered;
        }
    };

    this._compareCovered = function(a, b) {
        if (a.line == b.line) {
            return b.column - a.column;
        } else {
            return b.line - a.line;
        }
    };

    this._padLineNo = function(lineNo) {
        lineNo = lineNo + "";
        return ("     " + lineNo).substring(lineNo.length);
    }
}

_TestResultWriter.prototype.execute = function() {
    var self = this;

    if (!self.testResult) {
        console.log("Skipping output test results because missing details");
        return Promise.resolve();
    }

    return new Promise(function(resolve, reject) {
        var indexParts = [];
        self.cleanCoverageDir();
        self.appendCoverageWarnings(indexParts);
        self.appendTestFailures(indexParts);
        self.handleCoverage(indexParts)
            .then(function() {
                fs.writeFile(self.indexFilename, indexParts.join(""), "utf8", function(err) {
                    if (err) {
                        reject(err);
                    } else {
                        resolve();
                    }
                });
            })
            .catch(function(err) {
                reject(err);
            });
    });
}

_TestResultWriter.prototype.cleanCoverageDir = function() {
    try {
        fsutil.rmTreeSync(this.coverageDir, true);
        fs.mkdirSync(this.coverageDir);
    } catch (err) {
        gutil.log("WARNING: Unable to clean coverage directory: " + err);
    }
}

_TestResultWriter.prototype.appendCoverageWarnings = function(indexParts) {
    if (this.testResult.codeCoverageWarnings) {
        indexParts.push("<h3>Overall Warnings</h3>");
        indexParts.push("<ol>")
        this.testResult.codeCoverageWarnings.forEach(function(warning, i) {
            indexParts.push(util.format("<li>%s</li>", warning.message));
        });
        indexParts.push("</ol>");
    }
}

_TestResultWriter.prototype.appendTestFailures = function(indexParts) {
    if (this.testResult.failures) {
        indexParts.push("<h3>Test Failures</h3>");
        indexParts.push("<ol>");
        this.testResult.failures.forEach(function(failure, i) {
            indexParts.push(util.format(
                "<li>%s.%s<ul><li><pre>%s</pre></li><li><pre>%s</pre></li></ul></li>",
                failure.name, failure.methodName, failure.message, failure.stackTrace
            ));
        });
        indexParts.push("</ol>");
    }
}

_TestResultWriter.prototype.handleCoverage = function(indexParts) {
    var self = this;
    if (self.testResult.codeCoverage) {
        return self.makeCoverageFiles()
            .then(function(coverageResults) {

                indexParts.push("<h3>CodeCoverage</h3>");
                self.appendTotalCoverage(indexParts, coverageResults);
                indexParts.push("<table><tr><th>File</th><th>Uncovered</th><th>Coverage</th><th>%</th></tr>");

                coverageResults.sort(self._compareCoverage);
                coverageResults.forEach(function(coverage) {

                    var title = coverage.name;
                    if (coverage.filename) {
                        title = util.format(
                            "<a href=\"%s/%s\">%s</a>",
                            self.coverageDirUri,
                            coverage.filename,
                            coverage.name
                        );
                    }
                    var covered = coverage.numLocations - coverage.numLocationsNotCovered;
                    var percent = (coverage.numLocations == 0) ? "100%" : (Math.round((covered / coverage.numLocations) * 100) + "%");

                    indexParts.push(util.format(
                        "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>",
                        title,
                        coverage.numLocationsNotCovered,
                        covered + "/" + coverage.numLocations,
                        percent
                    ));

                });
                indexParts.push("</table>");
                return Promise.resolve();

            });
    } else {
        return Promise.resolve();
    }
}

_TestResultWriter.prototype.appendTotalCoverage = function(indexParts, coverageResults) {
    var self = this;
    var totalLinesNotCovered = 0;
    var totalLinesCovered = 0;
    var totalLines = 0;
    var percentCovered;
    coverageResults.forEach(function(coverage) {
        totalLines += coverage.numLocations || 0;
        totalLinesNotCovered += coverage.numLocationsNotCovered || 0;
    });
    totalLinesCovered = totalLines - totalLinesNotCovered;
    percentCovered = (Math.round((totalLinesCovered / totalLines) * 10000) / 100);
    indexParts.push(util.format(
        "<p><strong>Total:</strong> %s/%s (%s%%)</p>",
        totalLinesCovered,
        totalLines,
        percentCovered
    ));
}

_TestResultWriter.prototype.makeCoverageFiles = function() {
    var self = this;
    if (self.testResult.codeCoverage) {
        var coverageFilePromises = [];
        var coverageResults = [];
        self.testResult.codeCoverage.forEach(function(coverage, i) {
            coverageFilePromises.push(
                self.makeCoverageFile(coverage)
                    .then(function(filename) {
                        coverage.outFilename = filename;
                        coverageResults.push(coverage);
                        return Promise.resolve();
                    })
                    .catch(function(errMsg) {
                        gutil.log(errMsg);
                        coverage.outFilename = null;
                        coverageResults.push(coverage);
                        return Promise.resolve();
                    })
            );
        });
        return Promise.all(coverageFilePromises).then(function() {
            return Promise.resolve(coverageResults);
        });
    } else {
        return Promise.resolve([]);
    }
}

_TestResultWriter.prototype.makeCoverageFile = function(coverage) {
    var self = this;
    if (coverage.locationsNotCovered) {

        return new Promise(function(resolve, reject) {
            var filename = coverage.name + ".html";
            fs.readFile(self.srcDir + "/classes/" + coverage.name + ".cls", "utf8", function(err, contents) {
                if (err) {
                    reject("Unable to create coverage file " + filename + ": " + err);
                } else {
                    self.writeCoverageFile(coverage, filename, contents)
                        .then(function(filename) {
                            coverage.filename = filename;
                            resolve(filename);
                        })
                        .catch(function(err) {
                            gutil.log("Unable to create coverage file " + filename);
                            reject("Unable to create coverage file " + filename + ": " + err);
                        });
                }
            });
        });
    } else {
        return Promise.resolve(null);
    }
}

_TestResultWriter.prototype.writeCoverageFile = function(coverage, filename, contents) {
    var self = this;

    return new Promise(function(resolve, reject) {
        var magicErrStart = "!!!_";
        var magicErrEnd = "_!!!";
        var lines = contents.split(/\r\n|\r|\n/);
        var lineNumbers = [];

        coverage.locationsNotCovered.sort(self.compareCovered);
        coverage.locationsNotCovered.forEach(function(loc, i) {
            var l = lines[loc.line - 1];
            lines[loc.line - 1] = [
                l.substr(0, loc.column),
                magicErrStart,
                l.substr(loc.column, l.length), 
                magicErrEnd
            ].join("");
        });

        for (var i = 0; i < lines.length; i++) {
            var lineNo = (i + 1) + "";
            lineNo = ("     " + lineNo).substring(lineNo.length);
            lineNumbers.push(util.format("<pre style=\"margin:0\">%s.</pre>", lineNo));
        }

        for (var i = 0; i < lines.length; i++) {
            if (lines[i] == "") {
                lines[i] = "&nbsp;";
            } else {
                lines[i] = htmlEncode(lines[i]);
                lines[i] = lines[i].replace(magicErrStart, "<span style='background-color:#f99d94'>");
                lines[i] = lines[i].replace(magicErrEnd, "</span>");
            }
            lines[i] = util.format("<pre style='margin:0'>%s</pre>", lines[i]);
        }

        var content = util.format(
            "<table><tr><td>%s</td><td>%s</td></tr></table>",
            lineNumbers.join(""),
            lines.join("")
        );

        fs.writeFile(self.coverageDir + "/" + filename, content, "utf8", function(err) {
            if (err) {
                reject(err);
            } else {
                resolve(filename);
            }
        });
    });
}

exports.newInstance = newSFDCClient;
