/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * common.js
 *
 * Shared JS API for Avalanche
 */

/**
 * Handle validation of basic constraints
 */
export function inputValidator(ev, feedback)
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

export function passwordValidator(real, repeat, feedback)
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