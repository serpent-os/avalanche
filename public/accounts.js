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
 * Endpoints for the authentication API
 */
const accountEndpoints = {
    'register': '/api/v1/auth/register',
    'login': '/api/v1/auth/login',
    'logout': '/api/v1/auth/logout',
}

/**
 * As soon as DOM is available update the account button
 * (Prevents flickering)
 */
document.addEventListener('DOMContentLoaded', function(ev)
{
    const accountButton = document.getElementById('accountButton');
    if (accountButton == null)
    {
        return;
    }
    if (isLoggedIn())
    {
        accountButton.innerHTML = "Log out " + window.sessionStorage.getItem(AVALANCHE_USER_ID);
    } else {
        accountButton.innerHTML = "Log in";
    }
})

/**
 * Ensure correct integration for avalanche website use
 */
window.onload = function(ev)
{
    integrateLoginForm();
    integrateRegisterForm();

    console.log("Account logged in? " + isLoggedIn());
    console.log("Logged in as: " + window.sessionStorage.getItem(AVALANCHE_USER_ID));

    const accountButton = document.getElementById('accountButton');
    accountButton.onclick = function(ev)
    {
        ev.preventDefault();
        if (isLoggedIn())
        {
            return performLogout();
        }
        /* Go to login page */
        window.location.href = "/ac/login";
    }
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

    fetch(accountEndpoints['login'], {
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
        console.log("Logged in! " + JSON.stringify(result));
        window.sessionStorage.setItem(AVALANCHE_TOKEN_ID, result.token);
        window.sessionStorage.setItem(AVALANCHE_USER_ID, result.username);
        window.sessionStorage.setItem(AVALANCHE_USER_ROLE, result.role);
        window.location.href = "/";
    }).catch(error => console.log("shit... " + error));

    return false;
}

/**
 * Log the user out.
 */
function performLogout()
{
    fetch(accountEndpoints['logout'], {
        method: 'POST',
        headers: {
            'Authorization': 'Bearer ' + window.sessionStorage.getItem(AVALANCHE_TOKEN_ID)
        }
    }).then(response => {
        if (!response.ok)
        {
            throw new Error("Failed to logout");
        }
        console.log("Logged out");
        window.sessionStorage.clear();
        window.location.reload(true);
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