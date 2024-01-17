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
    ]
  }
};
