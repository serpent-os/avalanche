/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avl.js
 *
 * Avalanche connections, etc.
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

document.addEventListener('DOMContentLoaded', function(ev)
{
    loadConnections();
    setInterval(() => {
        loadConnections();
        return true;
    }, 1000);
});

function renderConnection(element)
{
    return `<div class="list-group-item gb-3 align-items-center">
<div class="row">
    <div class="col">
        ${element.id}
    </div>
    <div class="col-auto">
        <a href="" class="btn btn-primary">Accept</a>
    </div>
    <div class="col-auto">
        <a href="" class="btn btn-danger">Decline</a>
    </div>
</div>`;
}

function loadConnections()
{
    const list = document.getElementById('connectionList');
    fetch('/api/v1/services/enumerate', {
        credentials: 'include',
        headers: {
            Accept: 'application/json'
        },
        method: 'GET'
    }).then((response) => {
        if (!response.ok)
        {
            throw new Error('Failed to fetch connections: ' + response.statusText);
        }
        return response.json();
    }).then((obj) => {
        let newHTML = `<div class="list-group-header">Incoming connections</div>`;
        obj.forEach(element => {
            newHTML += renderConnection(element);
        });
        list.innerHTML = newHTML;
    }).catch((err) => console.log(err));
}