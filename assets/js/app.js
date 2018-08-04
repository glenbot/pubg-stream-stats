var root = null;
var useHash = true; // Defaults to: false
var hash = '#!'; // Defaults to: '#'
var router = new Navigo(root, useHash, hash);

const electron = require('electron');
const app_settings = require('electron-settings');
const battlegrounds = require('battlegrounds')
const fs = require('fs')
const sprintf = require("sprintf-js").sprintf
const mainProcess = electron.remote.require('./main')

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