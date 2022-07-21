/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * builders.js
 *
 * Helpers for the Builder APIs
 */

import * as validationModule from './common.js';

/**
 * Hook up submit button for adding builders
 */
window.onload = function(ev)
{
    const form = document.getElementById('addBuilderForm');
    const button = document.getElementById('addBuilderButton');
    const host = document.getElementById('host');
    const hostFeedback = document.getElementById('hostFeedback');

    host.addEventListener('input', ev => validationModule.inputValidator(ev, hostFeedback));

    button.onclick = function(ev)
    {
        ev.preventDefault();
        if (!host.validity.valid)
        {
            return false;
        }
        form.submit();
        return false;
    };
}