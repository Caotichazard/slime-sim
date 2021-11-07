#version 430

// Game of Life rendering shader
// Just renders the content of the ssbo at binding 1 to screen

#define WIN_SIZE 980



#define DIFFUSE_RATE 0.025
#define EVAPORATION_RATE 0.01


// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;

// Output fragment color
out vec4 finalColor;

// Input game of life grid.
layout(std430, binding = 1) buffer golLayout
{
    float golBuffer[];
};

// Output resolution
uniform vec2 resolution;
#define fetchGol(x, y) ((((x) < 0) || ((y) < 0) || ((x) > WIN_SIZE) || ((y) > WIN_SIZE)) \
    ? (0) \
    : golBuffer[(x) + WIN_SIZE * (y)])


uint hash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}



// Compound versions of the hashing algorithm I whipped together.
uint hash( uvec2 v ) { return hash( v.x ^ hash(v.y)                         ); }
uint hash( uvec3 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z)             ); }
uint hash( uvec4 v ) { return hash( v.x ^ hash(v.y) ^ hash(v.z) ^ hash(v.w) ); }



// Construct a float with half-open range [0:1] using low 23 bits.
// All zeroes yields 0.0, all ones yields the next smallest representable value below 1.0.
float floatConstruct( uint m ) {
    const uint ieeeMantissa = 0x007FFFFFu; // binary32 mantissa bitmask
    const uint ieeeOne      = 0x3F800000u; // 1.0 in IEEE binary32

    m &= ieeeMantissa;                     // Keep only mantissa bits (fractional part)
    m |= ieeeOne;                          // Add fractional part to 1.0

    float  f = uintBitsToFloat( m );       // Range [1:2]
    return f - 1.0;                        // Range [0:1]
}



// Pseudo-random value in half-open range [0:1].
float random( float x ) { return floatConstruct(hash(floatBitsToUint(x))); }
float random( vec2  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( vec3  v ) { return floatConstruct(hash(floatBitsToUint(v))); }
float random( vec4  v ) { return floatConstruct(hash(floatBitsToUint(v))); }

void main()
{
    ivec2 coords = ivec2(fragTexCoord*resolution);
    
    float blurResult = 0;

    if ((golBuffer[coords.x + coords.y*uvec2(resolution).x]) > 0.0){ 

        float originalValue = golBuffer[coords.x + coords.y*uvec2(resolution).x];
        
        finalColor = vec4(mix(vec3(0.0196, 0.5569, 0.6549),vec3(0.1804, 0.8314, 0.4549),(golBuffer[coords.x + coords.y*uvec2(resolution).x]*0.5)),golBuffer[coords.x + coords.y*uvec2(resolution).x]*10.0);

        blurResult += fetchGol(coords.x - 1, coords.y - 1);   // Top left
        blurResult += fetchGol(coords.x, coords.y - 1);       // Top middle
        blurResult += fetchGol(coords.x + 1, coords.y - 1);   // Top right
        blurResult += fetchGol(coords.x - 1, coords.y);       // Left
        blurResult += fetchGol(coords.x + 1, coords.y);       // Right
        blurResult += fetchGol(coords.x - 1, coords.y + 1);   // Bottom left
        blurResult += fetchGol(coords.x, coords.y + 1);       // Bottom middle   
        blurResult += fetchGol(coords.x + 1, coords.y + 1);   // Bottom right

        blurResult = blurResult / 9.0;

        golBuffer[coords.x + coords.y*uvec2(resolution).x] = mix(originalValue,blurResult,DIFFUSE_RATE) - EVAPORATION_RATE;
        
    }
    else{ finalColor = vec4(0.0, 0.0, 0.0, 1.0);}
}