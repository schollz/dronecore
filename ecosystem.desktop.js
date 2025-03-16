module.exports = {
    apps: [
        {
            name: "sclang_init",
            script: "./start.sh",
            cwd: "./supercollider",
            autorestart: false,
            wait_ready: false,   // Waits until it's fully started
            restart_delay: 5000, // Wait 5 seconds before restarting
        },
        {
            name: "jackd",
            script: "./jackd.sh",
            cwd: "./desktop",
            autorestart: true,
            wait_ready: false,   // Waits until it's fully started
            restart_delay: 5000, // Wait 5 seconds before restarting
        },
        {
            name: "sclang",
            script: "sclang",
            cwd: "./supercollider",
            args: "-d . -D timeandspace.scd",
            autorestart: true,
            wait_ready: true,   // Waits until it's fully started
            restart_delay: 5000, // Wait 5 seconds before restarting
        },
        {
            name: "desktop_display",
            script: ".venv/bin/python",
            args: "display.py",
            cwd: "./desktop",
            autorestart: true,
            wait_ready: false,    // Waits until previous process is ready
            watch: ["./desktop/display.py"],
            restart_delay: 1000, // Wait 3 seconds before restarting
        },
        {
            name: "orchestrator",
            script: "orchestrator",
            cwd: "./orchestrator",
            autorestart: true,
            wait_ready: false,    // Waits until previous process is ready
            restart_delay: 1000, // Wait 3 seconds before restarting
        },
        {
            name: "desktop_interface",
            script: ".venv/bin/python",
            args: "interface.py",
            cwd: "./desktop",
            autorestart: true,
            wait_ready: true,    // Waits until previous process is ready
            watch: ["./desktop/interface.py"],
            restart_delay: 1000, // Wait 3 seconds before restarting
        }
    ]
};
