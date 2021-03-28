#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

// From Processing 2.1 and up, this line is optional
#define PROCESSING_COLOR_SHADER

// if you are using the filter() function, replace the above with
// #define PROCESSING_TEXTURE_SHADER

// ----------------------
//  SHADERTOY UNIFORMS  -
// ----------------------

uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iTime;                 // shader playback time (in seconds) (replaces iGlobalTime which is now obsolete)
uniform float     iTimeDelta;            // render time (in seconds)
uniform int       iFrame;                // shader playback frame

uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
uniform vec4      iDate;                 // (year, month, day, time in seconds)

//uniform float     iChannelTime[2];
//uniform vec3      iChannelResolution[2];


// Channels can be either 2D maps or Cubemaps.
// Pick the ones you need and uncomment them.


// uniform float     iChannelTime[1..4];       // channel playback time (in seconds)
// uniform vec3      iChannelResolution[1..4]; // channel resolution (in pixels)

uniform sampler2D iChannel0;

/*
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

uniform samplerCube iChannel0;
uniform samplerCube iChannel1;
uniform samplerCube iChannel2;
uniform samplerCube iChannel3;

uniform vec3  iChannelResolution[4]; // channel resolution (in pixels)

uniform float iChannelTime[4]; // Channel playback time (in seconds)
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord );

void main() {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}

// ------------------------------
//  SHADERTOY CODE BEGINS HERE  -
// ------------------------------

const float INFINITY = 1.0 / 0.0;
const float M_PI = 3.1415926f;
const float DURATION = 100.;

const float earthRadius = 6360e3;
const float atmosphereRadius = 6420e3;
const float Hr =7994.; // original 7994, adds red/yellow tone to rise
const float Hm = 1200.; // size of sun
const vec3 betaR = vec3(3.8e-6, 13.5e-6,33.1e-6); // color of rise
const vec3 betaM = vec3(210e-6f); // size of sun 
// from 'the graphics codex'
// Ray-Sphere Intersection
bool raySphereIntersect(vec3 P, vec3 w, vec3 C, float r, out float t0, out float t1) { 
    vec3 v = P - C;
    
    float b = 2.0 * dot(w, v);
    float c = dot(v,v) - r * r;
    
    float d = b * b - 4.0 * c;
    
    if(d<0.0) return false;
    
    float s = sqrt(d);
    t0 = (-b-s) * 0.5;
    t1 = (-b+s) * 0.5f;
    
    return true;
}

vec3 computeIncidentLight(vec3 o, vec3 d, float tmin, float tmax, vec3 sunDirection)
{
    float t0, t1;
    if(!raySphereIntersect(o, d, vec3(0.0), atmosphereRadius, t0, t1) || t1 < 0.) return vec3(0.0);
    if(t0>tmin && t0>0.) tmin = t0;
    if(t1<tmax) tmax = t1;
    uint numSamples = 8u;
    uint numSamplesLight = 8u;
    float segmentLength = (tmax-tmin)/float(numSamples);
    float tCurrent = tmin;
    vec3 sumR = vec3(0.0);
    vec3 sumM = vec3(0.0);
    float opticalDepthR = 0.0;
    float opticalDepthM = 0.0;
    float mu = dot(d, sunDirection);
    float phaseR = 3.f / (16.f * M_PI) * ( 1. + mu * mu);
    float g = 0.76;
    float phaseM = 3. / (8. * M_PI) * ((1.-g*g)*(1. + mu*mu)) / ((2. + g*g) * pow(1. + g*g - 2. * g * mu, 1.5));
    vec3 betaRt = betaR*(1. + vec3(0.,2.,3.)*(iMouse.x/iResolution.x-.1));
    vec3 betaMt = betaM*(1. + 16.*iMouse.y/iResolution.y);
    
    for(uint i = 0u; i < numSamples; ++i) {
        vec3 samplePosition = o + (tCurrent + segmentLength * 0.5) * d;
        float height = length(samplePosition) - earthRadius;
        float hr = exp(-height/ Hr) * segmentLength;
        float hm = exp(-height/Hm) * segmentLength;
        opticalDepthR += hr;
        opticalDepthM += hm;
        float t0Light;
        float t1Light;
        raySphereIntersect(samplePosition, sunDirection, vec3(0.0), atmosphereRadius, t0Light, t1Light);
        float segmentLengthLight = t1Light / float(numSamplesLight);
        float opticalDepthLightR = 0.;
        float opticalDepthLightM = 0.;
        float tCurrentLight = 0.;
        uint j;
        for(j=0u;j<numSamplesLight;++j){
            vec3 samplePositionLight = samplePosition + (tCurrentLight + segmentLengthLight * 0.5) * sunDirection;
            float heightLight = length(samplePositionLight) - earthRadius;
            if(heightLight < 0.0) break;
            opticalDepthLightR += exp(-heightLight / Hr) * segmentLengthLight;
            opticalDepthLightM += exp(-heightLight / Hm) * segmentLengthLight;
            tCurrentLight += segmentLengthLight;
        }
        if(j==numSamplesLight) {
            vec3 tau = vec3(betaRt * (opticalDepthR + opticalDepthLightR) + betaMt * 1.1 * (opticalDepthM + opticalDepthLightM));
            vec3 attenuation = exp(-tau);
            sumR += attenuation * hr;
            sumM += attenuation * hm;
        }	
        tCurrent += segmentLength;
    }
    
    return vec3(sumR * betaRt * phaseR + sumM * betaMt * phaseM) * 20.;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    float angle = M_PI * (fract((float(iFrame)/DURATION+40.)/180.)*2.-1.);
    vec3  sunDirection = vec3(sin(angle), cos(angle), 0.0);

    // Normalized pixel coordinates (from 0 to 1)
    // vec2 uv = fragCoord/iResolution.xy  * 2.0-2.2;
    // vec2 uv = fragCoord/iResolution.xy  * 1.5 +10.;

    vec2 uv = fragCoord/iResolution.xy;
    uv.x *= iResolution.x / iResolution.y;
    
    float x = uv.x;
    float y = uv.y;
    float z2 = x*x + y*y;
    
    vec3 col = vec3(0.0);
    float scale = .4; // this adds more suns 
    //if(z2 <= 1.){
        float phi = (x/2. - 10./3. * iMouse.x / iResolution.x)*2.*M_PI*scale;
        float theta;
        if (fract((float(iFrame)/DURATION+40.)/180.) < .5) {
            theta = y*M_PI*scale-1.5;
        } else {
            theta = -(y*M_PI*scale-1.5);
        }
        vec3 dir = vec3(sin(theta)*cos(phi), cos(theta), sin(theta)*sin(phi));
        col = computeIncidentLight(vec3(0.0, earthRadius + 1., 0.0), dir, 0., INFINITY, sunDirection);
    //}
    

    // Output to screen
    // col = pow(col, vec3(1.0/2.5));
    // fragColor = vec4(col,1.0);
    
    // this makes really pretty gradients... 
    // if (uv.y < -.065) {
        //iMouse.x/iResolution.x
        fragColor = vec4(fragCoord/iResolution.xy, .5, 1.); //vec4(vec3(.3), 1.);
    // }
}