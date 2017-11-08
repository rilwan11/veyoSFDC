var fs = require("fs");
var through2 = require("through2");
var gutil = require("gulp-util");
var Vinyl = require("vinyl");
var fsutil = require("./fs-util.js");

/**
 * Checks if any of the input files are newer than the specified output file.
 * If they are, all of the files will be reintroduced into the stream.
 * Otherwise, none of them will be.
 */
exports.anyNewer = function(newerThan) {

    var outMTime = null;
    if (newerThan && typeof newerThan === "string") {
        try {
            var outStat = fs.statSync(newerThan);
            if (outStat) {
                outMTime = outStat.mtime;
            }
        } catch (err) {
            outMTime = null;
        }
    } else {
        outMTime = newerThan;
    }

    var allFiles = [];
    var foundOne = false;

    return through2.obj(function(file, enc, next) {

        if (file.isStream()) {
            next(new PluginError('pipe-util:anyNewer', 'Streaming not supported'));
            return;
        }

        allFiles.push(file);
        if (!foundOne) {
            if (!outMTime || (file && file.stat && file.stat.mtime && file.stat.mtime > outMTime)) {
                foundOne = true;
            }
        }
        next();
        return;

    }, function(next) {

        // Re-introduce all files if at least one was found with a more recent
        // modified date.
        var self = this;
        if (foundOne) {
            allFiles.forEach(function(file) {
                self.push(file);
            });
        }
        next();
        return;

    });
};

/**
 * Performs a quick newer check 
 */
exports.newer = function(newerThan) {

    var outMTime = null;
    if (newerThan && typeof newerThan === "string") {
        try {
            var outStat = fs.statSync(newerThan);
            if (outStat) {
                outMTime = outStat.mtime;
            }
        } catch (err) {
            outMTime = null;
        }
    } else {
        outMTime = newerThan;
    }

    return through2.obj(function(file, enc, next) {
        if (!outMTime || (file.stat && file.stat.mtime && file.stat.mtime > outMTime)) {
            next(null, file);
        } else {
            next();
        }
        return;
    });

}

/**
 * Creates a new, clean `vinyl` file with a last modified date of now and no
 * contents. This is just a shortcut methods for creating files.
 */
exports.newFile = function(filename) {
    stat = new fs.Stats();
    stat.atime = new Date();
    stat.mtime = new Date();
    stat.ctime = new Date();
    stat.birthtime = new Date();
    return new Vinyl({
        path: filename,
        stat: stat
    });
}
