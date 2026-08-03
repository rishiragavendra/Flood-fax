import type { Config } from "tailwindcss";

/**
 * The palette is cartographic rather than corporate-generic: paper and ink for
 * the document surfaces, one hydrographic blue for interaction, and a muted
 * earth ramp for risk. Nothing saturates past what would print legibly on a
 * survey sheet, which is the whole point — this is a document, not a dashboard
 * skin.
 */
const config: Config = {
  darkMode: "class",
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        paper: "rgb(var(--paper) / <alpha-value>)",
        surface: "rgb(var(--surface) / <alpha-value>)",
        raised: "rgb(var(--raised) / <alpha-value>)",
        ink: "rgb(var(--ink) / <alpha-value>)",
        muted: "rgb(var(--muted) / <alpha-value>)",
        rule: "rgb(var(--rule) / <alpha-value>)",
        hydro: {
          DEFAULT: "rgb(var(--hydro) / <alpha-value>)",
          soft: "rgb(var(--hydro-soft) / <alpha-value>)",
        },
        band: {
          low: "rgb(var(--band-low) / <alpha-value>)",
          moderate: "rgb(var(--band-moderate) / <alpha-value>)",
          elevated: "rgb(var(--band-elevated) / <alpha-value>)",
          high: "rgb(var(--band-high) / <alpha-value>)",
          severe: "rgb(var(--band-severe) / <alpha-value>)",
        },
      },
      fontFamily: {
        sans: ["var(--font-sans)", "ui-sans-serif", "system-ui", "sans-serif"],
        serif: ["var(--font-serif)", "ui-serif", "Georgia", "serif"],
        mono: ["var(--font-mono)", "ui-monospace", "SFMono-Regular", "monospace"],
      },
      fontSize: {
        eyebrow: ["0.6875rem", { lineHeight: "1rem", letterSpacing: "0.12em" }],
        display: ["clamp(2.6rem, 6vw, 4.4rem)", { lineHeight: "1.02", letterSpacing: "-0.03em" }],
        title: ["clamp(1.9rem, 3.4vw, 2.6rem)", { lineHeight: "1.1", letterSpacing: "-0.02em" }],
      },
      boxShadow: {
        card: "0 1px 2px rgb(16 26 30 / 0.04), 0 12px 32px -20px rgb(16 26 30 / 0.28)",
        lift: "0 2px 4px rgb(16 26 30 / 0.05), 0 28px 60px -32px rgb(16 26 30 / 0.42)",
      },
      maxWidth: {
        prose: "68ch",
        shell: "76rem",
      },
      keyframes: {
        rise: {
          "0%": { transform: "translateY(8px)", opacity: "0" },
          "100%": { transform: "translateY(0)", opacity: "1" },
        },
        sweep: {
          "0%": { transform: "translateX(-100%)" },
          "100%": { transform: "translateX(100%)" },
        },
      },
      animation: {
        rise: "rise 0.5s cubic-bezier(0.22, 1, 0.36, 1) both",
        sweep: "sweep 1.6s ease-in-out infinite",
      },
    },
  },
  plugins: [],
};

export default config;
