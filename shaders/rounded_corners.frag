#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
// uniform vec4 colDiffuse;

// Custom uniform values
uniform vec4 spriteUVBounds;
uniform float cornerRadius;

// Output fragment color
out vec4 finalColor;

void main()
{
    vec4 texelColor = texture(texture0, fragTexCoord);

    vec2 uvSize = spriteUVBounds.zw - spriteUVBounds.xy;
    vec2 cardSize = uvSize * vec2(textureSize(texture0, 0));
    vec2 pixelPos = ((fragTexCoord - spriteUVBounds.xy) / uvSize) * cardSize;

    vec2 quadrantPixel = abs(pixelPos - (cardSize * 0.5)) - ((cardSize * 0.5) - vec2(cornerRadius));

    float isCorner = step(0.0, quadrantPixel.x) * step(0.0, quadrantPixel.y);

    float alpha = 1.0 - smoothstep(cornerRadius - 1.0, cornerRadius, length(quadrantPixel));
    texelColor.a *= mix(1.0, alpha, isCorner);

    finalColor = texelColor * fragColor;
}
