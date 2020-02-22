import paranim/gl, paranim/gl/uniforms, paranim/gl/attributes
from paranim/primitives import nil
import paratext
import nimgl/opengl
import glm

type
  TextEntityUniforms = tuple[
    u_matrix: Uniform[Mat3x3[GLfloat]],
    u_translate_matrix: Uniform[Mat3x3[GLfloat]],
    u_scale_matrix: Uniform[Mat3x3[GLfloat]],
    u_texture_matrix: Uniform[Mat3x3[GLfloat]],
    u_image: Uniform[Texture[GLubyte]],
    u_color: Uniform[Vec4[GLfloat]]
  ]
  TextEntityAttributes = tuple[a_position: Attribute[GLfloat]]
  TextEntity* = object of ArrayEntity[TextEntityUniforms, TextEntityAttributes]
  UncompiledTextEntity* = object of UncompiledEntity[TextEntity, TextEntityUniforms, TextEntityAttributes]
  InstancedTextEntityUniforms = tuple[u_matrix: Uniform[Mat3x3[GLfloat]], u_image: Uniform[Texture[GLubyte]]]
  InstancedTextEntityAttributes = tuple[a_position: Attribute[GLfloat], a_matrix: Attribute[GLfloat], a_texture_matrix: Attribute[GLfloat]]
  InstancedTextEntity* = object of InstancedEntity[InstancedTextEntityUniforms, InstancedTextEntityAttributes]
  UncompiledInstancedTextEntity* = object of UncompiledEntity[InstancedTextEntity, InstancedTextEntityUniforms, InstancedTextEntityAttributes]

const textVertexShader =
  """
  #version 410
  uniform mat3 u_matrix;
  uniform mat3 u_translate_matrix;
  uniform mat3 u_scale_matrix;
  uniform mat3 u_texture_matrix;
  in vec2 a_position;
  out vec2 v_tex_coord;
  void main()
  {
    gl_Position = vec4((u_matrix * u_translate_matrix * u_scale_matrix * vec3(a_position, 1)).xy, 0, 1);
    v_tex_coord = (u_texture_matrix * vec3(a_position, 1)).xy;
  }
  """

const textFragmentShader =
  """
  #version 410
  precision mediump float;
  uniform sampler2D u_image;
  uniform vec4 u_color;
  in vec2 v_tex_coord;
  out vec4 o_color;
  void main()
  {
    o_color = texture(u_image, v_tex_coord);
    if (o_color.rgb == vec3(0.0, 0.0, 0.0))
    {
      discard;
    }
    else
    {
      o_color = u_color;
    }
  }
  """

proc initTextEntity*(font: Font): UncompiledTextEntity =
  result.vertexSource = textVertexShader
  result.fragmentSource = textFragmentShader
  # create attribute
  var position = Attribute[GLfloat](size: 2, iter: 1)
  new(position.data)
  position.data[].add(primitives.rectangle[GLfloat]())
  # create texture
  var image = Texture[GLubyte](
    opts: TextureOpts(
      mipLevel: 0,
      internalFmt: GL_RED,
      width: GLsizei(font.bitmap.width),
      height: GLsizei(font.bitmap.height),
      border: 0,
      srcFmt: GL_RED
    ),
    params: @[
      (GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE),
      (GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE),
      (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
      (GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    ]
  )
  new(image.data)
  image.data[].add(font.bitmap.data)
  # set attributes and uniforms
  result.attributes = (a_position: position)
  result.uniforms = (
    u_matrix: Uniform[Mat3x3[GLfloat]](data: mat3f(1)),
    u_translate_matrix: Uniform[Mat3x3[GLfloat]](data: mat3f(1)),
    u_scale_matrix: Uniform[Mat3x3[GLfloat]](data: mat3f(1)),
    u_texture_matrix: Uniform[Mat3x3[GLfloat]](data: mat3f(1)),
    u_image: Uniform[Texture[GLubyte]](data: image),
    u_color: Uniform[Vec4[GLfloat]](data: vec4(0f, 0f, 0f, 1f))
  )

const instancedTextVertexShader =
  """
  #version 410
  uniform mat3 u_matrix;
  in vec2 a_position;
  in vec4 a_color;
  in mat3 a_translate_matrix;
  in mat3 a_texture_matrix;
  in mat3 a_scale_matrix;
  out vec2 v_tex_coord;
  out vec4 v_color;
  void main()
  {
    gl_Position = vec4((u_matrix * a_translate_matrix * a_scale_matrix * vec3(a_position, 1)).xy, 0, 1);
    v_tex_coord = (a_texture_matrix * vec3(a_position, 1)).xy;
    v_color = a_color;
  }
  """

const instancedTextFragmentShader =
  """
  #version 410
  precision mediump float;
  uniform sampler2D u_image;
  in vec2 v_tex_coord;
  in vec4 v_color;
  out vec4 o_color;
  void main()
  {
    o_color = texture(u_image, v_tex_coord);
    if (o_color.rgb == vec3(0.0, 0.0, 0.0))
    {
      discard;
    }
    else
    {
      o_color = v_color;
    }
  }
  """
