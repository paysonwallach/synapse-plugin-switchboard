/*
 * Copyright (c) 2020 Payson Wallach
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

namespace Synapse {
    public struct PlugInfo {
        public string title;
        public string icon;
        public string uri;
        public string[] path;
    }

    [DBus (name = "io.elementary.ApplicationsMenu.Switchboard")]
    public class SwitchboardExecutablePlugin : Object {
        private PlugInfo[] plugs;

        public void set_plugs (PlugInfo[] plugs) throws Error {
            this.plugs = plugs;
        }

        [DBus (visible = false)]
        public PlugInfo[] get_plugs () {
            return plugs;
        }

    }

    public class SwitchboardObject : ActionMatch {
        public string uri { get; construct set; }

        public SwitchboardObject (PlugInfo plug_info) {
            Object (
                title: plug_info.title,
                description: @"Open $(plug_info.title) settings",
                icon_name: plug_info.icon,
                uri: plug_info.uri
                );
        }

        public override void do_action () {
            try {
                Gtk.show_uri_on_window (null, @"settings://$uri", Gdk.CURRENT_TIME);
            } catch (Error e) {
                warning ("Failed to show URI for %s: %s\n".printf (uri, e.message));
            }
        }

    }

    public class SwitchboardPlugin : Object, Activatable, ItemProvider {
        SwitchboardExecutablePlugin executable_plugin;
        WorkerLink worker_link;
        Subprocess subprocess;

        public bool enabled { get; set; default = true; }

        public void activate () {
            executable_plugin = new SwitchboardExecutablePlugin ();
            worker_link = new WorkerLink ();
            worker_link.on_connection_accepted.connect ((connection) => {
                try {
                    connection.register_object ("/io/elementary/applicationsmenu", executable_plugin);
                } catch (Error e) {
                    critical ("%s", e.message);
                }
            });

            worker_link.start ();

            var launcher = new SubprocessLauncher (SubprocessFlags.NONE);
            string[] argv = {
                Path.build_filename (Config.PLUGINS_DIR, "switchboard-plugin"),
                "--dbus-address=%s".printf (worker_link.address)
            };
            try {
                subprocess = launcher.spawnv (argv);
                subprocess.wait_check_async.begin (null, (obj, res) => {
                    try {
                        subprocess.wait_check_async.end (res);
                    } catch (Error e) {
                        critical ("%s", e.message);
                    }

                    subprocess = null;
                });
            } catch (Error e) {
                warning ("Failed to spawn %s", e.message);
            }
        }

        public void deactivate () {
            if (subprocess != null) {
                subprocess.force_exit ();
            }
        }

        public async ResultSet? search (Query q) throws SearchError {
            var plugs = executable_plugin.get_plugs ();

            var result = new ResultSet ();
            MatcherFlags flags;
            if (q.query_string.length == 1) {
                flags = MatcherFlags.NO_SUBSTRING | MatcherFlags.NO_PARTIAL | MatcherFlags.NO_FUZZY;
            } else {
                flags = 0;
            }
            var matchers = Query.get_matchers_for_query (q.query_string_folded, flags);

            string stripped = q.query_string.strip ();
            if (stripped == "") {
                return null;
            }

            foreach (unowned PlugInfo plug in plugs) {
                string searchable_name = plug.path.length > 0 ? plug.path[plug.path.length - 1] : plug.title;
                foreach (var matcher in matchers) {
                    MatchInfo info;
                    if (matcher.key.match (searchable_name.down (), 0, out info)) {
                        result.add (new SwitchboardObject (plug), MatchScore.AVERAGE);
                        break;
                    }
                }
            }
            q.check_cancellable ();

            return result;
        }
    }
}

Synapse.PluginInfo register_plugin () {
    return new Synapse.PluginInfo (
        typeof (Synapse.SwitchboardPlugin),
        "Switchboard Search",
        "Find switchboard plugs and open them.",
        "preferences-desktop",
        null,
        Environment.find_program_in_path ("io.elementary.switchboard") != null,
        "Switchboard is not installed."
        );
}
