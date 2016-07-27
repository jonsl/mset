
uniform int uMaxIterations;
varying highp vec2 vTexCoords;

highp float mandel() {

	highp vec2 c = vTexCoords;
	highp vec2 z = c;
	highp float l = 0.;

	for (int n=0; n<uMaxIterations; n++) {

		z = vec2( z.x*z.x - z.y*z.y, 2.*z.x*z.y ) + c;

		if( dot(z,z)>(256.*256.) ) {

			return l - log2(log2(dot(z, z))) + 4.;

		}

		l += 1.;

	}

	return 0.;

}

void main() {
	
	highp float n = mandel();

	//gl_FragColor = vec4(pow(sin(colourPhase.xyz * n + colourPhaseStart)*.5+.5,vec3(1.5)), 1.);
	gl_FragColor = vec4((-cos(0.025*n)+1.0)/2.0, (-cos(0.08*n)+1.0)/2.0, (-cos(0.12*n)+1.0)/2.0, 1.);
}
