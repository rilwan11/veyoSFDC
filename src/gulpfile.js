/**
 *
 * Gulp file for Salesforce deployment and dev utilities
 *
 * This file contains gulp tasks that help with Salesforce deployments
 * "deploy" and "deploy_clean".
 *
 * - "src": The source directory. Defaults to the current directory.
 * - "dir": The build directory. Defaults to "build"
 * - "org": The key for the org or group that you are interacting with. If not
 *          provided, this will pull the org specified as "$default". The orgs are
 *          defined in "builder-local/orgs.json" and "builder/orgs.json" (with the
 *          local orgs taking precedence).
 */

var path = require( "path" );
var readline = require( "readline" );

var argv = require( "yargs" ).argv;

var gulp = require( "gulp" );
var gutil = require( "gulp-util" );
var newer = require( "gulp-newer" );
var rename = require( "gulp-rename" );
var replace = require( "gulp-replace" );
var autoprefixer = require( "gulp-autoprefixer" );
var plumber = require( "gulp-plumber" );
var connect = require( "gulp-connect" );

var runSequence = require( "run-sequence" );
var through2 = require( "through2" );

var sfdcOrgs = require( "./builder/sfdc-orgs.js" );
var PackageBuilder = require( "./builder/sfdc-package-builder.js" );
var SFDCClient = require( "./builder/sfdc-client.js" );
var LastRun = require( "./builder/last-run.js" );
var fsutil = require( "./builder/fs-util.js" );
var pipeutil = require( "./builder/pipe-util.js" );

var opts = {
    srcRoot: argv.src || ".",
    buildRoot: argv.dir || "./build",
    orgKey: argv.org || "default",
    branches: argv.branches || null
}

if ( !opts.orgKey.match( /^[a-z0-9\-_\.@]+$/i ) ) {
    throw "Org key can only contain the following case-insensitive characters: a-z, 0-9, -, _, ., or @";
}

sfdcOrgs.load();
var orgs = sfdcOrgs.get( opts.orgKey );
var buildQuality = ( orgs ) ? orgs[ 0 ].quality : "dev";
var sfEnv = ( orgs ) ? orgs[ 0 ].environment : "prod";
var srcDir = opts.srcRoot;
var buildDir = opts.buildRoot + "/" + opts.orgKey;
var lastDeploy = LastRun.newInstance( buildDir, "deploy" );
var packageBuilder = PackageBuilder.newInstance( srcDir, buildDir, buildQuality, lastDeploy );

console.log( "============================================================" );
console.log( "Salesforce build tool:" );
console.log( "  Org(s): " + opts.orgKey );
console.log( "  Quality: " + buildQuality );
console.log( "  Environment: " + sfEnv );
console.log( "  Last deploy: " + lastDeploy.get() );
console.log( "============================================================" );
console.log( "" );

/**
 * Generates a callback that should be used in a "run sequence"
 */
function sequenceCallbackHandler( gulpCallback ) {
    return function( err ) {
        if ( err ) {
            // Silence the error; otherwise gulp will crash.
            gutil.log( gutil.colors.red( "Sequence Error" ), err.plugin, ( err.details || err.message || err ) );
            gulpCallback();
        } else {
            gulpCallback();
        }
    }
};

function promiseThenCB( gulpCallback ) {
    return function( data ) {
        gulpCallback();
    }
};

function promiseCatchCB( gulpCallback ) {
    return function( err ) {
        // Silence the error; otherwise gulp will crash.
        gutil.log( gutil.colors.red( "Promise Error" ), ( err.details || err.message || err ) );
        gulpCallback();
    }
};

/**
 * SALESFORCE PACKAGE TASKS
 *
 * Handles the copying of Salesforce package data and creating salesforce
 * package zip files which can then be deployed. This assumes all static
 * resources have already been packaged manually.
 */
gulp.task( "_sfdc_clean", function( cb ) {
    fsutil.rmTreeSync( buildDir + "/sfdc-package", true );
    lastDeploy.clear();
    cb();
    return;
} )

gulp.task( "_sfdc_clean_package_sync", function( cb ) {
    fsutil.rmTreeSync( buildDir + "/sfdc-package" );
    cb();
    return;
} )

gulp.task( "_sfdc_copy_package_files", function( cb ) {
    packageBuilder.copyPackageFiles().then( promiseThenCB( cb ), promiseCatchCB( cb ) );
} );

gulp.task( "_sfdc_copy_package_manifest", function( cb ) {
    packageBuilder.copyPackageManifest().then( promiseThenCB( cb ), promiseCatchCB( cb ) );
} );

gulp.task( "_sfdc_make_package_archive", function( cb ) {
    packageBuilder.buildPackageZip().then( promiseThenCB( cb ), promiseCatchCB( cb ) );
} );

gulp.task( "_sfdc_deploy_package", function( cb ) {
    packageBuilder.readPackageZip()
        .then( function( pkgData ) {
            var client;
            var deployPromises = [];
            orgs.forEach( function( org ) {
                client = SFDCClient.newInstance( org, buildDir, srcDir );
                deployPromises.push( client.login().then( function() {
                    return client.deploy( pkgData );
                }, function( err ) {
                    return Promise.reject( err );
                } ) );
            } );
            Promise.all( deployPromises ).then( promiseThenCB( cb ), promiseCatchCB( cb ) );
        } );
    return;
} );

gulp.task( "_sfdc_update_last_deploy", function( cb ) {
    lastDeploy.set( new Date() );
    cb();
    return;
} );

gulp.task( "_sfdc_build", function( cb ) {
    runSequence(
        "_sfdc_clean_package_sync", [ "_sfdc_copy_package_files" ],
        "_sfdc_copy_package_manifest",
        "_sfdc_make_package_archive",
        sequenceCallbackHandler( cb )
    );
} );

gulp.task( "_sfdc_deploy", function( cb ) {
    runSequence(
        "_sfdc_deploy_package",
        "_sfdc_update_last_deploy",
        sequenceCallbackHandler( cb )
    );
} )

/**
 * Other External Tasks
 */
gulp.task( "clean_all", function( cb ) {
    fsutil.rmTreeSync( opts.buildRoot );
    cb();
    return;
} );

gulp.task( "deploy", function( cb ) {
    if ( !orgs ) throw "No orgs configured for `" + opts.orgKey + "`. Is it in orgs.json?";
    runSequence(
        "_sfdc_build",
        "_sfdc_deploy",
        sequenceCallbackHandler( cb )
    );
} );

gulp.task( "deploy_clean", function( cb ) {
    if ( !orgs ) throw "No orgs configured for `" + opts.orgKey + "`. Is it in orgs.json?";
    runSequence(
        [ "_sfdc_clean" ],
        "_sfdc_build",
        "_sfdc_deploy",
        sequenceCallbackHandler( cb )
    );
} );

