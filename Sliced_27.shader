Shader "Game/27-Sliced"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        [Space(50)]
        _EdgeSize ("Edge Size",  FLOAT) = 0.1
        [Space(20)]
        _Threshold ("Threshold", VECTOR) = (0.05, 0.05, 0.05, 1)
        _Bound ("Original Mesh Bounds", VECTOR) = (0.5, 0.5, 0.5, 1)
        [Toggle(VISUALISE)]_Visualise("Visualise", FLOAT) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows addshadow vertex:vert

        #pragma target 3.0
        #pragma multi_compile _ VISUALISE

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            
            #ifdef VISUALISE
            float3 localPos;
            #endif
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        half _EdgeSize;
        half3 _Threshold;
        half3 _Bound;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float3 remap_center(float3 val, float3 bound, float3 from, float3 to){
            return saturate(
                lerp( 
                    val * to/from, 
                    (val-from)/(bound-from) * (bound-to) + to, 
                    step(from, val) 
                )
            );
        }

        void vert(inout appdata_full v, out Input IN){
            UNITY_INITIALIZE_OUTPUT(Input, IN);
            
            #ifdef VISUALISE
                IN.localPos = v.vertex.xyz;
            #else
            
                float3 scale;
                scale.x = length(mul(unity_ObjectToWorld, float4(1,0,0,0)));
                scale.y = length(mul(unity_ObjectToWorld, float4(0,1,0,0)));
                scale.z = length(mul(unity_ObjectToWorld, float4(0,0,1,0)));
                
                v.normal.xyz *= lerp( 1, scale, step(_Threshold, abs(v.vertex.xyz)) );
                float3 map = remap_center(abs(v.vertex.xyz), _Bound, _Threshold, _Bound-_EdgeSize/scale);
                v.vertex.xyz = map * sign(v.vertex.xyz);

            #endif
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

            #ifdef VISUALISE
                o.Albedo = step(_Threshold, abs(IN.localPos));
                fixed3 bound = step(abs(IN.localPos), _Bound);
                o.Albedo *= bound.x * bound.y * bound.z;
            #else
                o.Albedo = c.rgb;
            #endif

            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
