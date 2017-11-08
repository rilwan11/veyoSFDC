var fs = require("fs");

// Various deployment modes for orgs. Depending on the deployment mode for the
// org, the code will do a slight variation on the deployment.
//
// - DEPLOY_MODE_DEPLOY: Physically deploys the code to that org
// - DEPLOY_MODE_CHECK: Runs a check-only deployment, leaving the org unchanged
// - DEPLOY_MODE_RUN_TESTS: Runs a check-only deployment that ALSO runs all
//                          tests in the org, outputting a results file.
//
var DEPLOY_MODE_DEPLOY = "deploy";
var DEPLOY_MODE_CHECK = "check";
var DEPLOY_MODE_RUN_TESTS = "run-tests";

// Deployment type variables. Determines if any modifications to the code
// should be made based on deployment type
var DEPLOY_TYPE_DEV = "dev";
var DEPLOY_TYPE_QA = "qa";
var DEPLOY_TYPE_PRODUCTION = "production";

// Environment variables.  These determine which WSDL files to use
var ENV_SANDBOX = "test";
var ENV_PROD = "login";

var GLOBAL_ORG_PATH = "./builder/orgs.json";
var LOCAL_ORG_PATH = "./builder-local/orgs.json";
var _orgs;

/**
 * Loads up the global and local orgs from the appropriate files. Note that
 * local orgs will always take priority over global ones.
 */
var load = function() {
    _orgs = {};
    _loadOrgsFromFile(LOCAL_ORG_PATH);
    _loadOrgsFromFile(GLOBAL_ORG_PATH);
}


/**
 * Returns a list of all orgs associated with the given key. If the key is
 * blank or not provided, we will find anything related to they "$default" key
 * which is a magic value used specifically for this purpose.
 *
 * If a list of orgs is not found, an exception is thrown.
 */
var get = function(key) {
    if (!key) {
        key = "default";
    }
    orgs = _orgs[key];
    if (!orgs) {
        orgs = null;
    }
    return orgs;
}


/**
 * Opens the specified json file containing a list of org entires (either orgs
 * or groups)
 */
var _loadOrgsFromFile = function(orgsfilePath) {
    var contents;
    try {
        contents = fs.readFileSync(orgsfilePath);
    } catch (e) {
        console.warn("Unable to load global orgs json file");
        return;
    }
    if (contents && contents != "") {
        _loadOrgsFromEntires(JSON.parse(contents));
    }
}


/**
 * Loads org data from a list of org entry objects (which are either orgs or
 * org groups).
 */
var _loadOrgsFromEntires = function(orgEntries) {
    var key;
    orgEntries.forEach(function(orgEntry) {
        key = orgEntry["key"] || orgEntry["username"];
        if (key && orgEntry["orgs"]) {
            _loadOrgGroupFromEntry(key, orgEntry);
        } else if (key && orgEntry["username"] && orgEntry["password"]) {
            _loadOrgFromEntry(key, orgEntry);
        }
    });
}


/**
 * Places a single org into the orgs database (if it does not already exist).
 * If the org does exist, a warning will be displayed and the new org will be
 * skipped.
 *
 * Note that this will add a one-item array into the orgs database (since the
 * database returns everything in array format).
 */
var _loadOrgFromEntry = function(key, orgEntry) {
    if (! orgEntry["mode"]) {
        orgEntry["mode"] = DEPLOY_MODE_CHECK;
    }
    if (! orgEntry["quality"]) {
        orgEntry["quality"] = DEPLOY_TYPE_PRODUCTION;
    }
    _orgs[key] = [orgEntry];
}


/**
 * Places a new org group in the orgs database (if something with that key
 * does not already exist). An org group collects all orgs referenced within it.
 * If it references soemthing that does not already exist within the database,
 * an error will be thrown.
 */
var _loadOrgGroupFromEntry = function(key, orgEntry) {
    var orgs = [];
    var orgsForKey;
    orgEntry["orgs"].forEach(function(orgKey) {
        orgsForKey = _orgs[orgKey];
        if (!orgsForKey) {
            // TODO: Throw exception
            console.log("No orgs found for key ", key);
        } else {
            var sharedQuality = null;
            orgsForKey.forEach(function(org) {
                if (sharedQuality != null && sharedQuality != org.quality) {
                    throw "Org's build quality " + org.quality + " is not compatible with others in the group";
                }
                sharedQuality = org.quality;
                orgs.push(org);
            });
        }
    })
    _orgs[key] = orgs;
}

exports.load = load;
exports.get = get;
