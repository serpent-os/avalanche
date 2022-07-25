/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * register.js
 *
 * Validation for registration page
 */

import * as validationModule from './common.js';

/**
 * Ensure correct integration for avalanche website use
 */
window.addEventListener('load', function(ev)
{
    integrateRegisterForm();
});

/**
 * Registration form integration
 */
function integrateRegisterForm()
{
    let registerForm = document.getElementById('registerForm');

    /* Get validation working */
    const username = document.getElementById('username');
    const usernameFeedback = document.getElementById('usernameFeedback');
    const password = document.getElementById('password');
    const passwordFeedback = document.getElementById('passwordFeedback');
    const passwordRepeat = document.getElementById('passwordRepeat');
    const passwordRepeatFeedback = document.getElementById('passwordRepeatFeedback');

    username.addEventListener('input', ev => validationModule.inputValidator(ev, usernameFeedback));
    password.addEventListener('input', ev => validationModule.inputValidator(ev, passwordFeedback));
    password.addEventListener('input', ev => validationModule.passwordValidator(password, passwordRepeat, passwordRepeatFeedback));
    passwordRepeat.addEventListener('input', ev => validationModule.passwordValidator(password, passwordRepeat, passwordRepeatFeedback));
}