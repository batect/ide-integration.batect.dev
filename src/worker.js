addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request))
});

async function handleRequest(request) {
    const userAgent = request.headers.get('User-Agent');
    const forwardedFor = request.headers.get('X-Forwarded-For');
    console.log(`Processing request: HTTP ${request.method} ${request.url}, user agent is "${userAgent}", forwarded for is ${forwardedFor}`)

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
    // Note that these routes must be kept in sync with the paths in cloudflare_worker.tf
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
