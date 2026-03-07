namespace ShadowSettings {
    public class Application : Adw.Application {
        public Application () {
            Object (
                application_id: "io.github.matrixshader.ShadowSettings",
                flags: ApplicationFlags.DEFAULT_FLAGS
            );
        }

        protected override void activate () {
            var window = new ShadowSettings.Window (this);
            window.present ();
        }
    }
}
