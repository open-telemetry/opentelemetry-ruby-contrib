module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-case': [
      2,
      'never',
      [
        'upper-case',
        'pascal-case',
      ]
    ],
    'type-enum': [
      2,
      'always',
      [
        'chore',
        'ci',
        'docs',
        'feat',
        'fix',
        'perf',
        'refactor',
        'revert',
        'squash',
        'style',
        'test'
      ]
    ]
  }
};
