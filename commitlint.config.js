/** @type {import('@commitlint/types').UserConfig} */
export default {
  extends: ["@commitlint/config-conventional"],
  rules: {
    // Enforce the types used in this project
    "type-enum": [
      2,
      "always",
      ["feat", "fix", "test", "docs", "refactor", "chore", "ci"],
    ],
    // Enforce the scopes used in this project
    "scope-enum": [
      2,
      "always",
      [
        "auth",
        "csv",
        "ai",
        "transactions",
        "budgets",
        "alerts",
        "charts",
        "api",
        "db",
        "config",
      ],
    ],
    "subject-case": [2, "always", "lower-case"],
    "subject-max-length": [2, "always", 72],
    "body-max-line-length": [2, "always", 100],
  },
};
