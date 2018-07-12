<?php

$electrumhost = 'electrum-daemon';
$host = 'http://electrum:passw0rd@' . $electrumhost;

return [
    'host'          => $host,
    'port'          => '7777',
    'web_interface' => [
        'enabled'    => true,
        'currency'   => 'JPY',
        'middleware' => ['web', 'auth'],
        'prefix'     => 'electrum',
    ],
];
