/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * login.js
 *
 * Validation for login page
 */

import * as validationModule from './common.js';

/**
 * Ensure correct integration for avalanche website use
 */
window.addEventListener('load', function(ev)
{
    integrateLoginForm();
});

/**
 * When required, integrate the login form.
 */
function integrateLoginForm()
{
    let loginForm = document.getElementById('loginForm');

    /* Hook up the username + password validity checks (min length, required) */
    const username = document.getElementById('username');
    const usernameFeedback = document.getElementById('usernameFeedback');
    const password = document.getElementById('password');
    const passwordFeedback = document.getElementById('passwordFeedback');
    const form = document.getElementById('loginForm');
    const button = document.getElementById('loginButton');

    button.onclick = function(ev)
    {
        ev.preventDefault();
        form.submit();
        return false;
    };

    username.addEventListener('input', ev => validationModule.inputValidator(ev, usernameFeedback));
    password.addEventListener('input', ev => validationModule.inputValidator(ev, passwordFeedback));

}