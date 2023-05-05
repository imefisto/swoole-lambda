<?php

declare(strict_types=1);

\Swoole\Runtime::enableCoroutine();

use GuzzleHttp\Client;
use Monolog\Handler\StreamHandler;
use Monolog\Level;
use Monolog\Logger;
use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Factory\AppFactory;
use Swoole\Coroutine\Channel;

require '/opt/vendor/autoload.php';

$app = AppFactory::create();
$logger = new Logger('name');
$logger->pushHandler(new StreamHandler('php://stderr', Level::Info));

$app->get('/', function (Request $request, Response $response, $args) use ($logger) {
    $start = microtime(true);
    $urls = explode(',', getenv('URLS'));

    $client = new Client([
        'verify' => '/opt/cacert.pem'
    ]);

    $logger->info('Starting');
    $chan = new Channel(count($urls));

    foreach ($urls as $url) {
        $logger->info('Requesting ' . $url);

        go(function () use ($client, $url, $chan) {
            $start = microtime(true);
            $res = $client->request('GET', $url);
            $elapsedTime = microtime(true) - $start;
            $chan->push([$url, $res->getStatusCode(), $elapsedTime]);
        });
    }

    $body = [
        'urls' => [],
        'totalElapsedTime' => 0,
    ];

    for ($i = 0; $i < count($urls); $i++) {
        $body['urls'][] = $chan->pop();
    }

    $logger->info('Done');

    $body['totalElapsedTime'] = microtime(true) - $start;

    $response->getBody()->write(json_encode($body));
    return $response
        ->withHeader('Content-Type', 'application/json');
});

return $app;
