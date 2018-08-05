<run>
    <div class="row justify-content-center">
        <div class="col-sm text-center">
            <button hide={ streamRunning } type="button" onclick={ runStream } class="btn btn-success"><i class="fas fa-play"></i> Run</button>
            <button show={ streamRunning } type="button" onclick={ stopStream } class="btn btn-danger"><i class="fas fa-stop"></i> Stop</button>
        </div>
    </div>
    <div class="row">&nbsp;</div>
    <div class="row justify-content-center">
        <div class="col-sm text-center">
            <div ref="logOutput" id="log-output" class="text-left">
                <p each={ logLines }>{ message }</p>
            </div>
        </div>
    </div>

    <script>
        // application settings
        this.app_settings = app_settings.get('app_settings');

        // check to see if the user has setup settings before and
        // initaliaze API accordingly
        if (this.app_settings === undefined) {
            this.battlegrounds = null;
        } else {
            this.battlegrounds = new battlegrounds(this.app_settings.api_key, this.app_settings.region)
        }

        // stream logging holder for set interval
        this._logLines = [];

        // stream logging
        this.logLines = [];

        // stream toggle used to show hide elements in the UI
        this.streamRunning = false;

        // the stream interval timer
        this.streamInterval = null;

        // An in memory cache of stats from PUBG api
        // This should get reset when a player name has been
        // changed in settings
        this.statsCache = {};

        /* This will automatically scroll the logging element */
        this.updateLogScroll = function() {
            if (this.refs.logOutput) {
                this.refs.logOutput.scrollTop = this.refs.logOutput.scrollHeight;
            }
        }

        /* write log to the UI */
        this.writeLog = function(message) {
            var date = new Date();
            var _message = sprintf('[%1$s] %2$s', date.toISOString(), message);
            this._logLines.push({message: _message});
            this.update({
                logLines: this._logLines
            });
            this.updateLogScroll();
        }

        /* Join a path and filename together based on OS */
        this.joinFilePath = function(path, file) {
            if (process.platform == 'windows') {
                return path + '\\' + file;
            } else {
                return path + '/' + file;
            }
        }

        /* Write a file out to the filesystem */
        this.writeFile = function(_file, contents) {
            fs.writeFile(this.joinFilePath(this.app_settings.stats_location, _file), contents, (err) => {
                if (err) {
                    this.writeLog('Error. Could not save files. Please check your directory in settings.')
                };
            });
        }

        this.abort = function() {
            this.streamRunning = false;
            this.update({
                streamRunning: false
            });
            clearInterval(this.streamInterval);
            this.writeLog('Stats streaming stopped.');
        }

        /* 
        * Parse the stats out and return them ready to save to files 
        * player (object) Player object from the stats API
        * stats (list) A list of the stats we care about in the payload
        * match_count (integer) A number of matches you want to aggregate data for. Filename
                          will have this number in it

        Example filename: <player_name>_<match_count>_kills.txt

        This function returns a dictionary where the key is the player name and the stats
        are the value
        */
        this.parseStats = async function(player, stats, statsAverage, matchCount) {
            var playerName = player.attributes.name;

            // check for players that have matches
            if (player.matches.length == 0) {
                this.writeLog(sprintf('Player [%s] does not have any matches', playerName));
                this.abort();
                return
            }

            // log the total number of matches found
            this.writeLog(vsprintf('Number of matches found: %s', player.matches.length));
            this.statsCache[playerName] = {
                matchIds: [],
                matchStats: {}
            }

            // output of parsed stats
            var parsedStats = {};
            parsedStats[playerName] = {};

            // setup all of the stats variables
            for (var i in stats) {
                parsedStats[playerName][stats[i]] = 0;
            }

            var statsCache = this.statsCache[playerName];

            // cache matches by ids and match objects
            for (var match in player.matches.slice(0, matchCount)) {
                var _match = player.matches[match];

                // if there are MAX matches and we have a newer match let's save this match and pop
                // the older one off
                if ((statsCache.matchIds.length == matchCount) && (statsCache.matchIds.indexOf(_match.id) < 0)) {
                    this.writeLog(vsprintf('Found new match [%s]. Updating.', _match.id));
                    var matchStats = await this.battlegrounds.getMatch({id: _match.id });
                    statsCache.matchIds.unshift(_match.id);
                    statsCache.matchStats[_match.id] = matchStats;

                    // remove the oldest match
                    this.writeLog(vsprintf('Clearing out oldest match.'));
                    delete statsCache.matchStats[statsCache.matchIds.pop()];
                } else if (statsCache.matchIds.indexOf(_match.id) < 0) {
                    this.writeLog(vsprintf('Found match [%s]. Updating.', _match.id));
                    var matchStats = await this.battlegrounds.getMatch({id: _match.id });
                    statsCache.matchIds.push(_match.id);
                    statsCache.matchStats[_match.id] = matchStats;
                }
            }

            // go through matches and pull out stats for playerName
            for (var i in statsCache.matchIds) {
                var matchStats = statsCache.matchStats[statsCache.matchIds[i]];
                
                // let's loop through the participants and get the statics for
                // the player we care about
                for (var j in matchStats.participants) {
                    var participant = matchStats.participants[j];
                    if (participant.attributes.stats.playerId == player.id) {
                        for (var k in stats) {
                            var stat = participant.attributes.stats[stats[k]];
                            if (stat !== undefined) {
                                parsedStats[playerName][stats[k]] += math.round(stat, 2);
                            }
                        }
                    }
                }
            }

            // go through statsAverage and calculate averages
            for (var i in statsAverage) {
                var stat = statsAverage[i];
                var value = parsedStats[playerName][statsAverage[i]];
                parsedStats[playerName][vsprintf('%sAvg', stat)] = math.round(value / matchCount, 2);
            }

            return parsedStats;
        }

        /* Write all the stats out to separate files */
        this.writeStats = function(player, parsedStats, matchCount) {
            for (var i in parsedStats) {
                var playerName = i;
                for (var j in parsedStats[playerName]) {
                    fileName = sprintf('%s_%s_%s.txt', playerName, matchCount, j);
                    fileContents = sprintf('Last %s %s: %s', matchCount, j, parsedStats[playerName][j]);
                    this.writeFile(fileName, fileContents);
                }
            }
        }

        /* 
        * Meat of application, the function pulls the stats and sends
        * them to parseStats 
        */
        this.processStats = (async function() {
            this.writeLog('Retrieving stats.');

            // Player should never be cached because we want fresh set of matches every time
            // Also if the player name is updated in settings we should update the files
            try {
                var players = await this.battlegrounds.getPlayers({ names: [this.app_settings.player_name] });
            } catch(err) {
                this.writeLog(err);
                this.abort();
                return
            }
            const player = players[0];

            // stats we care to write to files.
            // TODO: make this configurable in the settings and make the
            // prefix in the content configurable
            var stats = [
                'DBNOs',
                'assists',
                'damageDealt',
                'headshotKills',
                'kills'
            ]

            // state we want averages on
            var statsAverage = [
                'kills',
                'damageDealt'
            ];

            // get stats for the last 5 matches
            parsedStats = await this.parseStats(player, stats, statsAverage, 5)

            // write the stats out
            this.writeStats(player, parsedStats, 5);

            // finito
            this.writeLog('Done.');
        }).bind(this);

        async runStream(e) {
            e.preventDefault();
            // grab the settings everytime
            this.app_settings = app_settings.get('app_settings');

            // let the user know they have now setup the application yet
            if (this.app_settings === undefined) {
                this.writeLog('Cannot run yet. Please visit the settings page to setup the application and click run again.');
                return
            }

            // setup the API instance
            if (this.battlegrounds == null) {
                this.app_settings = app_settings.get('app_settings');
                this.battlegrounds = new battlegrounds(this.app_settings.api_key, this.app_settings.region);
            }

            this.writeLog('Stats streaming started.');
            this.streamRunning = true;
            this.processStats();
            this.streamInterval = setInterval(this.processStats, 60000);
        }

        stopStream(e) {
            e.preventDefault();
            this.streamRunning = false;
            clearInterval(this.streamInterval);
            this.writeLog('Stats streaming stopped.');
        }

        this.writeLog('Welcome to PUBG stream stats. Please check your settings and click run to start.');
    </script>
</run>