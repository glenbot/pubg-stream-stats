<settings>
    <form onsubmit={ saveSettings }>
        <div class="row">
            <div class="col-sm-10 offset-sm-1">
                <div class="input-group mb-3">
                    <div class="input-group input-group-lg">
                        <div class="input-group-prepend">
                            <span class="input-group-text" id="inputGroup-sizing-lg">PUBG API Key</span>
                        </div>
                        <input type="password" id="apiKey" class="form-control" aria-label="Large" aria-describedby="inputGroup-sizing-sm" value="{ settings.api_key }" />
                    </div>
                </div>

                <div class="input-group mb-3">
                    <div class="input-group">
                        <div class="input-group-prepend">
                            <span class="input-group-text" id="inputGroup-sizing-lg">Player Name</span>
                        </div>
                        <input type="text" id="playerName" class="form-control" aria-label="Large" aria-describedby="inputGroup-sizing-sm" value="{ settings.player_name }" />
                    </div>
                </div>

                <div class="input-group mb-3">
                    <div class="input-group-prepend">
                        <label class="input-group-text" for="region">Region</label>
                    </div>
                    <select class="custom-select" id="region">
                        <option>Choose Region...</option>
                        <option each={regions} value="{value}" selected={ settings.region == value }>{name}</option>
                    </select>
                </div>

                <div class="input-group mb-3">
                    <div class="input-group">
                        <div class="input-group-prepend">
                            <span class="input-group-text" id="inputGroup-sizing-lg">Stats Location</span>
                        </div>
                        <input type="text" onclick="{ selectDirectory }" id="statsLocation" class="form-control" aria-label="Large" aria-describedby="inputGroup-sizing-sm" value="{ settings.stats_location }" />
                    </div>
                </div>
            </div>
        </div>
        <div class="row">&nbsp;</div>
        <div class="row">
            <div class="col-sm text-center">
                <button class="btn btn-primary"><i class="fas fa-save"></i> Save Settings</button>
            </div>
        </div>
        <div class="row">&nbsp;</div>
        <div class="row">
            <div class="col-sm text-center">
                <div id="save-success" class="alert alert-success hidden" role="alert">Settings saved successfully!</div>
                <div id="save-failed" class="alert alert-warning hidden" role="alert">
                    <ul>
                        <li each={ messages }>{ message }</li>
                    <ul>
                </div>
            </div>
        </div>
    </form>

    <script>
        this.settings = {};
        this.messages = [];

        var _settings = app_settings.get('app_settings');

        // copy over the cached settings to be able to show
        // them on the interface
        if (_settings !== undefined) {
            for (var i in _settings) {
                this.settings[i] = _settings[i];
            }
        }

        // TODO - check if all of these work?? I don't know
        // if some of these are missing payloads. I have removed
        // tournament and xbox for fear of missing attributes 
        this.regions = [
            { value: "pc-krjp", name: "pc-krjp - Korea"},
            { value: "pc-jp", name: "pc-jp - Japan"},
            { value: "pc-na", name: "pc-na - North America"},
            { value: "pc-eu", name: "pc-eu - Europe"},
            { value: "pc-ru", name: "pc-ru - Russia"},
            { value: "pc-oc", name: "pc-oc - Oceania"},
            { value: "pc-kakao", name: "pc-kakao - Kakao"},
            { value: "pc-sea", name: "pc-sea - South East Asia"},
            { value: "pc-sa", name: "pc-sa - South and Central America"},
            { value: "pc-as", name: "pc-as - Asia"}    
        ];

        this.validateValues = function(values) {
            fail_count = 0;
            this.messages = [];

            if (values.api_key == '') {
                this.messages.push({message: 'Please enter in an api key'});
                fail_count += 1;
            }
            if (values.player_name == '') {
                this.messages.push({message: 'Please enter in a player name'});
                fail_count += 1;
            }
            if (values.region === 'Choose Region...') {
                this.messages.push({message: 'Please select a region'});
                fail_count += 1;
            }
            if (values.stats_location == '' || values.stats_location == 'undefined') {
                this.messages.push({message: 'Please select a valid directory.'});
                fail_count += 1;
            }
            if (fail_count > 0)
                return false;
            return true;
        }

        /* Pull the values from the form, validate, and inject them in the app_settings cache */
        saveSettings(e) {
            e.preventDefault();
            $('#save-failed').hide();
            values = {
                api_key: apiKey.value,
                region: region.value,
                player_name: playerName.value.trim(),
                stats_location: statsLocation.value
            };
            if (this.validateValues(values)) {
                app_settings.set('app_settings', values);
                $('#save-success').show().fadeOut(2000);
            } else {
                $('#save-failed').show();
            }
        }

        selectDirectory(e) {
            statsLocation.value = mainProcess.selectDirectory();
        }
    </script>
</settings>