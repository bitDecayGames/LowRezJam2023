package shaders;

import flixel.FlxG;

class PixelateShader extends flixel.system.FlxAssets.FlxShader
{
    var debug = false;
    var enabled = true;

    @:glFragmentSource('
        #pragma header

        // effect enabled
        uniform bool iEnabled;

        // draw grid
        uniform bool iDebug;

        // size of pixels along x/y axes
        uniform vec2 iPixelSize;

        void main()
        {
            // Pixel size of the underlying texture
            vec2 iResolution = openfl_TextureSize;

            // downsample rate (ex: 512x512 / 64x64 = 8x8)
            vec2 iPixelateRes = iResolution * iPixelSize;

            vec2 sampleUV = floor(openfl_TextureCoordv / iPixelSize) * iPixelSize;
            vec4 col = texture2D(bitmap, sampleUV);
            
            if (!iEnabled) {
                col = texture2D(bitmap, openfl_TextureCoordv);
            }

            if (iDebug) {
                vec2 uv = openfl_TextureCoordv;
                // original pixel coordinate on our texture
                vec2 fragPixelCoord = uv * iResolution.xy;
                
                // divide by our pixel size to get our downsampled pixel coordinate
                vec2 iPixelCoord = fragPixelCoord / iPixelateRes.xy;

                // Draw grid
                if (mod(iPixelCoord.x, 2.) < 1. && mod(iPixelCoord.y, 2.) < 1.) {
                    col.xyz *= .8;
                } else if (mod(iPixelCoord.x, 2.) >= 1. && mod(iPixelCoord.y, 2.) >= 1.) {
                    col.xyz *= .8;
                }
            }

            gl_FragColor = col;
        }
    ')

    public function new() {
        super();
        this.iPixelSize.value = [1 / 64, 1 / 64];
        this.iDebug.value = [debug];
        this.iEnabled.value = [enabled];
    }

    public function update(elapsed:Float)
    {
        if (FlxG.keys.justPressed.P) {
            enabled = !enabled;
            this.iEnabled.value = [enabled];
        }

        if (FlxG.keys.justPressed.O) {
            debug = !debug;
            this.iDebug.value = [debug];
        }
    }
}
