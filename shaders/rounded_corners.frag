#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
// uniform vec4 colDiffuse;

// Custom uniform values
uniform vec4 spriteUVBounds;

// Output fragment color
out vec4 finalColor;

void main()
{
    // Texel color fetching from texture sampler
    vec4 texelColor=texture(texture0,fragTexCoord);
    vec2 localUV=(fragTexCoord-spriteUVBounds.xy)/(spriteUVBounds.zw-spriteUVBounds.xy);
    vec2 quadrantUV=abs(localUV-vec2(.5,.5));
    float r=.08;
    // NOTE: Implement here your fragment shader code^
    
    if(length(quadrantUV-vec2(0.5-r,0.5-r))>r&&quadrantUV.x>0.5-r&&quadrantUV.y>0.5-r){
        texelColor.a=0;
    }
    // final color is the color from the texture
    //    times the tint color (colDiffuse)
    //    times the fragment color (interpolated vertex color)
    finalColor=texelColor;
}

// #version 330

// // Input vertex attributes (from vertex shader)
// in vec2 fragTexCoord;
// in vec4 fragColor;
// in vec4 fragPosition:

// // Input uniform values
// uniform sampler2D texture0;
// uniform vec4 colDiffuse;

// // Output fragment color
// out vec4 finalColor;

// // NOTE: Add your custom variables here

// void main()
// {
    
    //         // Texel color fetching from texture sampler
    //         vec4 texelColor=texture(texture0,fragTexCoord);
    //         // NOTE: Implement here your fragment shader code
    
    //         float radius=.1;
    
    //         float dist=sdRoundedBox(texture0,texture0,vec4(radius))
    
    //         // final color is the color from the texture
    //         //    times the tint color (colDiffuse)
    //         //    times the fragment color (interpolated vertex color)
    
    //         finalColor=vec4(texelColor.rgb,texelColor.a*dist);
// }