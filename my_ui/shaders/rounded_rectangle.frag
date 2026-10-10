#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
// uniform vec4 colDiffuse;

// Custom uniform values
uniform vec4 spriteUVBounds;
uniform float radius;
uniform float borderWidth; // Thickness of the border in pixels
uniform vec4 borderColor; // Color of the border (RGBA)

// Output fragment color
out vec4 finalColor;

void main()
{
    vec4 texelColor = texture(texture0, fragTexCoord);

    vec2 uvSize = spriteUVBounds.zw - spriteUVBounds.xy;
    vec2 subRectSize = uvSize * vec2(textureSize(texture0, 0));
    vec2 pixelPos = ((fragTexCoord - spriteUVBounds.xy) / uvSize) * subRectSize;

    vec2 innerBoxHalfSize = (subRectSize * 0.5) - vec2(radius);
    vec2 quadrantPixel = abs(pixelPos - (subRectSize * 0.5)) - innerBoxHalfSize;

    float dist = length(max(quadrantPixel, vec2(0.0))) + min(max(quadrantPixel.x, quadrantPixel.y), 0.0) - radius;

    float outerAlpha = 1.0 - smoothstep(-0.5, 0.5, dist);
    float innerAlpha = 1.0 - smoothstep(-0.5, 0.5, dist + borderWidth);

    float borderFactor = clamp(outerAlpha - innerAlpha, 0.0, 1.0);

    vec4 baseColor = texelColor * fragColor;
    vec4 resultColor = mix(baseColor, borderColor, borderFactor);

    resultColor.a *= outerAlpha;

    finalColor = resultColor;
}

// #version 330

// // Input vertex attributes (from vertex shader)
// in vec2 fragTexCoord;
// in vec4 fragColor;

// // Input uniform values
// uniform sampler2D texture0;
// uniform vec4 colDiffuse;

// // Custom uniform values
// uniform vec4 spriteUVBounds;
// uniform float radius;

// // Output fragment color
// out vec4 finalColor;

// void main()
// {
//     vec4 texelColor = texture(texture0, fragTexCoord);

//     vec2 uvSize = spriteUVBounds.zw - spriteUVBounds.xy;
//     vec2 subRectSize = uvSize * vec2(textureSize(texture0, 0));
//     vec2 pixelPos = ((fragTexCoord - spriteUVBounds.xy) / uvSize) * subRectSize;

//     vec2 quadrantPixel = abs(pixelPos - (subRectSize * 0.5)) - ((subRectSize * 0.5) - vec2(radius));

//     float isCorner = step(0.0, quadrantPixel.x) * step(0.0, quadrantPixel.y);

//     float alpha = 1.0 - smoothstep(radius - 1.0, radius, length(quadrantPixel));
//     texelColor.a *= mix(1.0, alpha, isCorner);

//     finalColor = texelColor * fragColor;
// }
