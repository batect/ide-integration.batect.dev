addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request))
});

async function handleRequest(request) {
    env.ANALYTICS.writeDataPoint({
        'blobs': [request.method, request.url, request.headers.get('User-Agent'), request.headers.get('X-Forwarded-For')],
        'doubles': [1],
    });

    if (request.method !== "GET") {
        return new Response("Method not allowed", { status: 405 });
    }

    const originResponse = await getResponse(request);
    const modifiedResponse = new Response(originResponse.body, originResponse);

    modifiedResponse.headers.set('Content-Security-Policy', "default-src 'none'; frame-ancestors 'none'");
    modifiedResponse.headers.set('X-Frame-Options', 'DENY');
    modifiedResponse.headers.set('X-Content-Type-Options', 'nosniff');
    modifiedResponse.headers.set('Referrer-Policy', 'no-referrer');

    return modifiedResponse;
}

async function getResponse(request) {
    if (request.url === 'https://ide-integration.batect.dev/v1/configSchema.json') {
        return await fetch(new Request('https://storage.googleapis.com/batect-ide-integration-prod-public/v1/configSchema.json'));
    } else if (request.url === 'https://ide-integration.batect.dev/ping') {
        return new Response('pong', { status: 200 });
    } else if (request.url === 'https://ide-integration.batect.dev/') {
        return new Response('', { status: 200 });
    } else {
        return new Response('Not found', { status: 404 });
    }
}
