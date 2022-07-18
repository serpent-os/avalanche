/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * accounts.js
 *
 * Handles account integration for Avalanche
 *
 */

const AVALANCHE_TOKEN_ID = 'AVALANCHE_TOKEN';
const AVALANCHE_USER_ID  = 'AVALANCHE_USER';
const AVALANCHE_USER_ROLE = 'AVALANCHE_ROLE';

/**
 * Ensure correct integration for avalanche website use
 */
window.onload = function(ev)
{
    integrateLoginForm();
    integrateRegisterForm();
}

/**
 * When required, integrate the login form.
 */
function integrateLoginForm()
{
    let loginForm = document.getElementById('loginForm');
    if (loginForm == null)
    {
        return;
    }
    /* Hook up the username + password validity checks (min length, required) */
    const username = document.getElementById('username');
    const usernameFeedback = document.getElementById('usernameFeedback');
    const password = document.getElementById('password');
    const passwordFeedback = document.getElementById('passwordFeedback');

    loginForm.onsubmit = ev => {
        ev.preventDefault();
        return performLogin(ev.target);
    };

    username.addEventListener('input', ev => inputValidator(ev, usernameFeedback));
    password.addEventListener('input', ev => inputValidator(ev, passwordFeedback));
}

/**
 * Registration form integration
 */
function integrateRegisterForm()
{
    let registerForm = document.getElementById('registerForm');
    if (registerForm == null)
    {
        return;
    }

    registerForm.onsubmit = ev => {
        ev.preventDefault();
        return false;
    }

    /* Get validation working */
    const username = document.getElementById('username');
    const usernameFeedback = document.getElementById('usernameFeedback');
    const password = document.getElementById('password');
    const passwordFeedback = document.getElementById('passwordFeedback');
    const passwordRepeat = document.getElementById('passwordRepeat');
    const passwordRepeatFeedback = document.getElementById('passwordRepeatFeedback');

    username.addEventListener('input', ev => inputValidator(ev, usernameFeedback));
    password.addEventListener('input', ev => inputValidator(ev, passwordFeedback));
    password.addEventListener('input', ev => passwordValidator(password, passwordRepeat, passwordRepeatFeedback));
    passwordRepeat.addEventListener('input', ev => passwordValidator(password, passwordRepeat, passwordRepeatFeedback));
}

/**
 * Handle validation of basic constraints
 */
function inputValidator(ev, feedback)
{
    if (!ev.target.validity.valid)
    {
        ev.target.classList.add('is-invalid');
        feedback.innerHTML = ev.target.validationMessage;
    } else {
        ev.target.classList.remove('is-invalid');
        feedback.innerHTML = '';
    }
}

function passwordValidator(real, repeat, feedback)
{
    if (real.value != repeat.value && repeat.value.length > 0)
    {
        repeat.classList.add('is-invalid');
        feedback.innerHTML = 'Passwords do not match';
    } else {
        repeat.classList.remove('is-invalid');
        feedback.innerHTML = '';
    }
}

/**
 * Perform an actual login using the auth API, save the cheerleader
 */
function performLogin(form)
{
    let fe = new FormData(form);
    const request = {
        "username": fe.get('username'),
        "password": fe.get('password'),
    };

    console.log('Sending... ' + JSON.stringify(request));

    const button = document.getElementById('loginButton');
    button.disabled = true;

    fetch('/api/v1/auth/login', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(request),
    }).then(response => {
        button.disabled = false;
        if (!response.ok)
        {
            throw new Error("Failed to login");
        }
        return response.json();
    }).then(result => {
        console.log("Logged in! " + result);
        window.sessionStorage.setItem(AVALANCHE_TOKEN_ID, result.token);
        window.sessionStorage.setItem(AVALANCHE_USER_ID, result.username);
        window.sessionStorage.setItem(AVALANCHE_USER_ROLE, result.role);
    }).catch(error => console.log("shit... " + error));

    return false;
}

/**
 * Log the user out.
 */
function performLogout()
{
    fetch('/api/v1/auth/logout', {
        method: 'POST',
        headers: {
            'Authorization': 'Bearer ' + token
        }
    }).then(response => {
        if (!response.ok)
        {
            throw new Error("Failed to logout");
        }
        console.log("Logged out");
        window.sessionStorage.clear();
    }).catch(error => console.log("shit... " + error));

    return false;
}

/**
 * Check if the users logged in.
 * 
 * @returns true if we're logged in
 */
function isLoggedIn()
{
    return window.sessionStorage.getItem(AVALANCHE_TOKEN_ID) != null;
}