var fs = require("fs");
var gulp = require("gulp");
var newer = require("gulp-newer");
var zip = require("gulp-zip");
var rename = require("gulp-rename");
var replace = require("gulp-replace");
var plumber = require("gulp-plumber");
var fsutil = require("./fs-util.js");
var pipeutil = require("./pipe-util.js");

/**
 * The SFDC Package Builder is used to create package files that can be
 * deployed to Salesforce via the metadata API.
 */
SFDCPackageBuilder = function(srcDir, buildDir, quality, lastRun) {
    if (!srcDir || !buildDir) {
        throw "The source and build directories must be specified!";
    }
    this.inDir = srcDir;
    this.outDir = buildDir + "/sfdc-package";
    this.staticResourceSrc = buildDir + "/static";
    this.packageManifestFilename = "package.xml";
    this.outFilename = "package.zip";
    this.lastRun = lastRun;
}

/**
 * Copies all of the normal files to the output directory.
 * Does not handle the static resource building -- assumes that
 * they have already been packaged manually. Returns a promise
 * that will resolve once all files have been copied.
 * 
 * Update this list for "only" what is necessary to deploy
 */
SFDCPackageBuilder.prototype.copyPackageFiles = function() {
    return Promise.all([
        this.copyDirectory("classes"),
        this.copyDirectory("components"),
        this.copyDirectory("customPermissions"),
        this.copyDirectory("flexipages"),
        this.copyDirectory("labels"),
        this.copyDirectory("layouts"),
        this.copyDirectory("objects"),
        this.copyDirectory("objectTranslations"),
        this.copyDirectory("pages"),
        this.copyDirectory("permissionsets"),
        this.copyDirectory("profiles"),
        this.copyDirectory("staticresources"),
        this.copyDirectory("triggers"),
    ]);
};

/**
 * Returns the date/time that this package should be built from.
 */
SFDCPackageBuilder.prototype.getSince = function() {
    return (this.lastRun) ? this.lastRun.get() : null;
};

/**
 * Copies a single package directory, returning a promise for when the
 * copy is completed.
 */
SFDCPackageBuilder.prototype.copyDirectory = function(copyDir) {
    var self = this;
    return (new Promise(function(resolve, reject) {
        var since = self.getSince();
        gulp.src(copyDir + "/**")
            .pipe(plumber())
            .pipe(pipeutil.newer(since))
            .pipe(gulp.dest(self.outDir + "/" + copyDir))
            .on("end", resolve);
    }))
    .then(function() {
        return self.fillMissingMetas(copyDir);
    })
    .then(function() {
        return self.fillMissingMains(copyDir);
    });
};

/**
 * Looks through the build directory named by "copyDir", finds any files that
 * have a metadata files in source but don't have one in the build. If there are any
 * missing metadata files, they will be copied to the build folder.
 */
SFDCPackageBuilder.prototype.fillMissingMetas = function(copyDir) {
    var self = this;
    var outDir = self.outDir + "/" + copyDir;
    var inDir = copyDir;
    return new Promise(function(resolve, reject) {
        fs.readdir(outDir, function(err, files) {
            if (err) {
                if (err.code == "ENOENT") {
                    resolve();
                } else {
                    reject(err);
                }
            } else {
                var foundFiles = {};
                files.forEach(function(filename) {
                    if (filename.endsWith("-meta.xml")) {
                        foundFiles[filename] = true;
                    } else {
                        foundFiles[filename + "-meta.xml"] = false;
                    }
                });
                var toCopy = [];
                for (filename in foundFiles) {
                    if (!foundFiles[filename]) {
                        toCopy.push(filename);
                    }
                }
                gulp.src(toCopy, {cwd: inDir, nodir: true})
                    .pipe(plumber())
                    .pipe(gulp.dest(outDir))
                    .on("end", resolve);
            }
        });
    });
}

/**
 * TODO: Implement
 */
SFDCPackageBuilder.prototype.fillMissingMains = function(copyDir) {
    return Promise.resolve();  // TODO: Implement...
}

/**
 * Copies the package.xml file to the output directory, returning a promise for
 * when the copy is completed.
 */
SFDCPackageBuilder.prototype.copyPackageManifest = function() {
    var self = this;
    return new Promise(function(resolve, reject) {
        var since = self.getSince();
        if (since) {
            gulp.src("builder/include-all-package.xml")
                .pipe(plumber())
                .pipe(rename("package.xml"))
                .pipe(gulp.dest(self.outDir))
                .on("end", resolve);
        } else {
            gulp.src(self.packageManifestFilename)
                .pipe(plumber())
                .pipe(gulp.dest(self.outDir))
                .on("end", resolve);
        }
    });
};

/**
 * Creates a package zip file and writes it to the file system. Returns a 
 * promise that will resolve once complete.
 */
SFDCPackageBuilder.prototype.buildPackageZip = function() {
    var self = this;
    return new Promise(function(resolve, reject) {
        gulp.src([
                self.outDir + "/**",
                "!" + self.outDir + "/" + self.staticResourceSrc + "/",
                "!" + self.outDir + "/" + self.staticResourceSrc + "/**"
            ])
            .pipe(plumber())
            .pipe(zip(self.outFilename))
            .pipe(gulp.dest(self.outDir))
            .on("end", resolve);
    });
};

/**
 * Loads the package file, returning a promise that will resolve with the
 * file contents of the zip file.
 */
SFDCPackageBuilder.prototype.readPackageZip = function() {
    var self = this;
    return new Promise(function(resolve, reject) {
        fs.readFile(self.outDir + "/" + self.outFilename, function(err, data) {
            if (err) {
                reject(err);
            } else {
                resolve(data);
            }
        });
    });
};

exports.newInstance = function(inDir, outDir, quality, lastRun) {
    return new SFDCPackageBuilder(inDir, outDir, quality, lastRun);
};
