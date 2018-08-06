var root = null;
var useHash = true; // Defaults to: false
var hash = '#!'; // Defaults to: '#'
var router = new Navigo(root, useHash, hash);

const electron = require('electron');
const appSettings = require('electron-settings');
const battlegrounds = require('battlegrounds')
const fs = require('fs')
const sprintf = require("sprintf-js").sprintf
const mainProcess = electron.remote.require('./main')

// stats we care to write to files.
// TODO: make this configurable in the settings and make the
// prefix in the content configurable
const stats = [
    'DBNOs',
    'assists',
    'damageDealt',
    'damageDealtAvg',
    'headshotKills',
    'kills',
    'killsAvg'
]

// default labels for stats (what gets written to the file)
const statsLabels = [
    { name: 'DBNOs', value: 'Last %(count)s DBNOs: %(value)s'},
    { name: 'assists', value: 'Last %(count)s assists: %(value)s' },
    { name: 'damageDealt', value: 'Last %(count)s damageDealt: %(value)s' },
    { name: 'damageDealtAvg', value: 'Last %(count)s damageDealtAvg: %(value)s' },
    { name: 'headshotKills', value: 'Last %(count)s headshotKills: %(value)s' },
    { name: 'kills', value: 'Last %(count)s kills: %(value)s' },
    { name: 'killsAvg', value: 'Last %(count)s killsAvg: %(value)s' },
];

// state we want averages on
const statsAverage = [
    'kills',
    'damageDealt'
];

$(function () {

var routes = $('div[data-route]');

/* Router content setter */
function setContent(route) {
    var route = $(`div[data-route='${route}']`);
    routes.hide();
    route.show();
}

/* Application routes */
router.on({
    'settings': function() {
        setContent('settings');
    },
    '*': function () {
        setContent('index');
    }
}).resolve();

riot.mount('*');

});