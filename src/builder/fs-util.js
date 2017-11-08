var fs = require("fs");
var path = require("path");
var util = require("util");
var _0777 = parseInt('0777', 8);

/**
 * Utility function to synchronously delete an entire directory tree.
 */
var rmTreeSync = function(dirPath, rmSelf) {
    try {
        var files = fs.readdirSync(dirPath);
    } catch(e) {
        return;
    }
    files.forEach(function(filename) {
        var filePath = dirPath + '/' + filename;
        if (fs.statSync(filePath).isFile()) {
            fs.unlinkSync(filePath);
        } else {
            rmTreeSync(filePath, true);
        }
    });
    if (rmSelf) {
        fs.rmdirSync(dirPath);
    }
};


/** 
 * Utility function that checks if *any* files within the directory tree have
 * been modified since the specified date.
 */
var modSinceTreeSync = function(dirPath, modSince) {
    if (!modSince) return true;

    try {
        var dirStat = fs.statSync(dirPath);
        var dirMod = new Date(util.inspect(dirStat.mtime));
        if (dirMod && modSince < dirMod) {
            //console.log("Found directory `" + dirPath + "` modified since " + modSince);
            return true;
        }
    } catch(e) {
        console.log("sinceTreeSync > Unable to stat " + dirPath);
    }

    try {
        var files = fs.readdirSync(dirPath);
    } catch(e) {
        return false;
    }

    for (var i = 0; i < files.length; i++) {
        var filePath = dirPath + '/' + files[i];
        var fileStat = fs.statSync(filePath);
        if (fileStat.isFile()) {
            var fileMod = new Date(util.inspect(fileStat.mtime));
            if (fileMod && modSince < fileMod) {
                //console.log("Found file `" + filePath + "` modified since " + modSince);
                return true;
            }
        } else {
            if (modSinceTreeSync(filePath, modSince)) {
                return true;
            }
        }
    }

    return false;
}

var modSinceFileSync = function(filename, modSince) {
    if (!modSince) return true;

    if (typeof modSince === "string") {
        try {
            var outStat = fs.statSync(modSince);
        } catch (err) {
            return true;  // No output file exists
        }
        modSince = new Date(util.inspect(outStat.mtime));
    }

    try {
        var fileStat = fs.statSync(filename);
        var fileMod = new Date(util.inspect(fileStat.mtime));
        if (fileMod && modSince < fileMod) {
            return true;
        } else {
            return false;
        }
    } catch (err) {
        return false;
    }
}

/**
 * Makes a directory tree if it doesn't exist. Lifted from 
 * https://github.com/substack/node-mkdirp/blob/master/index.js
 *
 * Open source used under MIT license
 */
var makeDirsSync = function (p, opts, made) {
    if (!opts || typeof opts !== 'object') {
        opts = { mode: opts };
    }
    
    var mode = opts.mode;
    var xfs = opts.fs || fs;
    
    if (mode === undefined) {
        mode = _0777 & (~process.umask());
    }
    if (!made) made = null;

    p = path.resolve(p);

    try {
        xfs.mkdirSync(p, mode);
        made = made || p;
    }
    catch (err0) {
        switch (err0.code) {
            case 'ENOENT' :
                made = makeDirsSync(path.dirname(p), opts, made);
                makeDirsSync(p, opts, made);
                break;

            // In the case of any other error, check if the dir exists.
            // If so, then cool; otherwise, bummer...
            default:
                var stat;
                try {
                    stat = xfs.statSync(p);
                }
                catch (err1) {
                    throw err0;
                }
                if (!stat.isDirectory()) throw err0;
                break;
        }
    }

    return made;
};

exports.rmTreeSync = rmTreeSync;
exports.modSinceTreeSync = modSinceTreeSync;
exports.modSinceFileSync = modSinceFileSync;
exports.makeDirsSync = makeDirsSync;