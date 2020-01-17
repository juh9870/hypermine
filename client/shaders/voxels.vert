#version 450

#include "common.h"
#include "surface-extraction/surface.h"

layout(location = 0) out vec3 texcoords_out;
layout(location = 1) out float occlusion;

layout(set = 1, binding = 0) readonly restrict buffer Surfaces {
    Surface surfaces[];
};

const uvec3 vertices[12][6] = {
    {{0, 0, 0}, {0, 0, 1}, {0, 1, 1}, {0, 0, 0}, {0, 1, 1}, {0, 1, 0}}, // -X
    {{0, 0, 0}, {1, 0, 0}, {1, 0, 1}, {0, 0, 0}, {1, 0, 1}, {0, 0, 1}}, // -Y
    {{0, 0, 0}, {0, 1, 0}, {1, 1, 0}, {0, 0, 0}, {1, 1, 0}, {1, 0, 0}}, // -Z

    {{0, 0, 0}, {0, 1, 1}, {0, 0, 1}, {0, 0, 0}, {0, 1, 0}, {0, 1, 1}}, // +X
    {{0, 0, 0}, {1, 0, 1}, {1, 0, 0}, {0, 0, 0}, {0, 0, 1}, {1, 0, 1}}, // +Y
    {{0, 0, 0}, {1, 1, 0}, {0, 1, 0}, {0, 0, 0}, {1, 0, 0}, {1, 1, 0}}, // +Z

    // Versions of the above with the diagonal going the other way (flipped)
    {{0, 0, 0}, {0, 0, 1}, {0, 1, 0}, {0, 1, 1}, {0, 1, 0}, {0, 0, 1}}, // -X
    {{0, 0, 0}, {1, 0, 0}, {0, 0, 1}, {1, 0, 1}, {0, 0, 1}, {1, 0, 0}}, // -Y
    {{0, 0, 0}, {0, 1, 0}, {1, 0, 0}, {1, 1, 0}, {1, 0, 0}, {0, 1, 0}}, // -Z

    {{0, 0, 0}, {0, 1, 0}, {0, 0, 1}, {0, 1, 1}, {0, 0, 1}, {0, 1, 0}}, // +X
    {{0, 0, 0}, {0, 0, 1}, {1, 0, 0}, {1, 0, 1}, {1, 0, 0}, {0, 0, 1}}, // +Y
    {{0, 0, 0}, {1, 0, 0}, {0, 1, 0}, {1, 1, 0}, {0, 1, 0}, {1, 0, 0}}, // +Z
};

const uvec2 texcoords[4][6] = {
    {{0, 0}, {0, 1}, {1, 1}, {0, 0}, {1, 1}, {1, 0}},
    {{0, 0}, {1, 1}, {0, 1}, {0, 0}, {1, 0}, {1, 1}},
    // Flipped versions
    {{0, 0}, {0, 1}, {1, 0}, {1, 1}, {1, 0}, {0, 1}},
    {{0, 0}, {1, 0}, {0, 1}, {1, 1}, {0, 1}, {1, 0}},
};

// a is half extent, point is [0,1]^3
// returns affine klein coordinates
vec4 cube_vertex(float a, vec3 point) {
    const float w = sqrt(3*pow(a,2)+1);
    point = point * 2 - 1;
    return vec4(point * vec3(a, a, a), w);
}

void main()  {
    uint index = gl_VertexIndex / 6;
    uint vertex = gl_VertexIndex % 6;
    Surface s = surfaces[index];
    uvec3 pos = get_pos(s);
    uint axis = get_axis(s);
    uvec2 uv = texcoords[axis / 3][vertex];
    texcoords_out = vec3(uv, get_mat(s) - 1);
    occlusion = get_occlusion(s, uv);
    vec3 relative_coords = vertices[axis][vertex] + pos;
    gl_Position = projection * cube_vertex(1, relative_coords / 16);
}
