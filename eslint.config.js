const lwcConfig = require('@salesforce/eslint-config-lwc');
const eslintAura = require('@salesforce/eslint-plugin-aura');
const jestPlugin = require('eslint-plugin-jest');
const globals = require('globals');

module.exports = [
    // LWC
    ...lwcConfig.configs.recommended.map((config) => ({
        ...config,
        files: ['force-app/main/default/lwc/**/*.js'],
    })),

    // Aura
    ...eslintAura.configs.recommended.map((config) => ({
        ...config,
        files: ['force-app/main/default/aura/**/*.js'],
    })),
    {
        files: ['force-app/main/default/aura/**/*.js'],
        languageOptions: {
            ecmaVersion: 2020,
        },
        rules: {
            'vars-on-top': 'off',
            'no-unused-expressions': 'off',
            'no-unused-vars': 'off',
        },
    },

    // テストファイル
    {
        files: ['**/*.test.js'],
        plugins: { jest: jestPlugin },
        rules: {
            ...jestPlugin.configs['flat/recommended'].rules,
            '@lwc/lwc/no-unexpected-wire-adapter-usages': 'off',
        },
        languageOptions: {
            globals: {
                ...globals.node,
            },
        },
    },
];
