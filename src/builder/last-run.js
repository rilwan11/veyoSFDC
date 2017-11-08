var fs = require("fs");
var path = require("path");

var FILE_NAME = "lastrun.txt";

function LastRun(buildDir, key) {
    if (key) {
        this.fileName = path.join(buildDir, "lastrun-" + key + ".txt");
    } else {
        this.fileName = path.join(buildDir, "lastrun.txt");
    }
    this.buildDir = buildDir;
    this.since = undefined;
}

LastRun.prototype._load = function() {
    try {
        var rawDate = fs.readFileSync(this.fileName, "utf8");
        this.since = new Date(rawDate);
    } catch (e) {
        if (e.code !== "ENOENT") {
            throw e;
        } else {
            this.since = null;
        }
    }
}

LastRun.prototype.get = function() {
    if (this.since === undefined) {
        this._load();
    }
    return this.since;
}

LastRun.prototype.set = function(when) {
    if (!when) {
        when = new Date();
    }
    this.since = undefined;
    fs.writeFileSync(this.fileName, when.toJSON(), "utf8");
}

LastRun.prototype.clear = function() {
    try {
        fs.unlinkSync(this.fileName);
    } catch (e) {
        if (e.code !== "ENOENT") {
            throw e;
        }
    } finally {
        this.since = undefined;
    }
}

exports.newInstance = function(buildDir, key) {
    return new LastRun(buildDir, key);
}
