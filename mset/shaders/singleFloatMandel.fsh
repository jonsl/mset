
uniform int u_iterations;
uniform highp float u_cr;
uniform highp float u_ci;
uniform highp float u_dcr;
uniform highp float u_dci;

varying highp vec2 v_texCoords;

highp float mandel() {

	highp vec2 c = vec2(u_cr, u_ci) + v_texCoords * vec2(u_dcr, u_dci);
	highp vec2 z = c;
	highp float l = 0.;

	for (int n=0; n<u_iterations; n++) {

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
