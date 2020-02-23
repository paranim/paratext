import paranim/gl, paranim/gl/uniforms, paranim/gl/attributes
from paranim/gl/entities import crop
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
  InstancedTextEntityAttributes = tuple[
    a_position: Attribute[GLfloat],
    a_translate_matrix: Attribute[GLfloat],
    a_scale_matrix: Attribute[GLfloat],
    a_texture_matrix: Attribute[GLfloat],
    a_color: Attribute[GLfloat]
  ]
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

proc initInstancedEntity*(entity: UncompiledTextEntity): UncompiledInstancedTextEntity =
  result.vertexSource = instancedTextVertexShader
  result.fragmentSource = instancedTextFragmentShader
  result.uniforms.u_matrix = entity.uniforms.u_matrix
  result.uniforms.u_image = entity.uniforms.u_image
  result.attributes.a_translate_matrix = Attribute[GLfloat](disable: true, divisor: 1, size: 3, iter: 3)
  new(result.attributes.a_translate_matrix.data)
  result.attributes.a_scale_matrix = Attribute[GLfloat](disable: true, divisor: 1, size: 3, iter: 3)
  new(result.attributes.a_scale_matrix.data)
  result.attributes.a_texture_matrix = Attribute[GLfloat](disable: true, divisor: 1, size: 3, iter: 3)
  new(result.attributes.a_texture_matrix.data)
  result.attributes.a_color = Attribute[GLfloat](disable: true, divisor: 1, size: 4, iter: 1)
  new(result.attributes.a_color.data)
  deepCopy(result.attributes.a_position, entity.attributes.a_position)

proc addInstanceAttr[T](attr: var Attribute[T], uni: Uniform[Mat3x3[T]]) =
  for r in 0 .. 2:
    for c in 0 .. 2:
      attr.data[].add(uni.data.row(r)[c])
  attr.disable = false

proc addInstanceAttr[T](attr: var Attribute[T], uni: Uniform[Vec4[T]]) =
  for x in 0 .. 3:
    attr.data[].add(uni.data[x])
  attr.disable = false

proc setInstanceAttr[T](attr: var Attribute[T], i: int, uni: Uniform[Mat3x3[T]]) =
  for r in 0 .. 2:
    for c in 0 .. 2:
      attr.data[r*3+c+i*9] = uni.data.row(r)[c]
  attr.disable = false

proc setInstanceAttr[T](attr: var Attribute[T], i: int, uni: Uniform[Vec4[T]]) =
  for x in 0 .. 3:
    attr.data[x+i*4] = uni.data[x]
  attr.disable = false

proc getInstanceAttr[T](attr: Attribute[T], i: int, uni: var Uniform[Mat3x3[T]]) =
  for r in 0 .. 2:
    for c in 0 .. 2:
      uni.data[r][c] = attr.data[r*3+c+i*9]
  uni.data = uni.data.transpose()
  uni.disable = false

proc getInstanceAttr[T](attr: Attribute[T], i: int, uni: var Uniform[Vec4[T]]) =
  for x in 0 .. 3:
    uni.data[x] = attr.data[x+i*4]
  uni.disable = false

proc add*(instancedEntity: var UncompiledInstancedTextEntity, entity: UncompiledTextEntity) =
  addInstanceAttr(instancedEntity.attributes.a_translate_matrix, entity.uniforms.u_translate_matrix)
  addInstanceAttr(instancedEntity.attributes.a_scale_matrix, entity.uniforms.u_scale_matrix)
  addInstanceAttr(instancedEntity.attributes.a_texture_matrix, entity.uniforms.u_texture_matrix)
  addInstanceAttr(instancedEntity.attributes.a_color, entity.uniforms.u_color)
  # instanceCount will be computed by the `compile` proc

proc add*(instancedEntity: var InstancedTextEntity, entity: UncompiledTextEntity) =
  addInstanceAttr(instancedEntity.attributes.a_translate_matrix, entity.uniforms.u_translate_matrix)
  addInstanceAttr(instancedEntity.attributes.a_scale_matrix, entity.uniforms.u_scale_matrix)
  addInstanceAttr(instancedEntity.attributes.a_texture_matrix, entity.uniforms.u_texture_matrix)
  addInstanceAttr(instancedEntity.attributes.a_color, entity.uniforms.u_color)
  instancedEntity.instanceCount += 1

proc `[]`*(instancedEntity: InstancedTextEntity or UncompiledInstancedTextEntity, i: int): UncompiledTextEntity =
  result.vertexSource = textVertexShader
  result.fragmentSource = textFragmentShader
  result.attributes.a_position = instancedEntity.attributes.a_position
  result.attributes.a_position.disable = false
  result.uniforms.u_image = instancedEntity.uniforms.u_image
  result.uniforms.u_image.disable = false
  getInstanceAttr(instancedEntity.attributes.a_translate_matrix, i, result.uniforms.u_translate_matrix)
  getInstanceAttr(instancedEntity.attributes.a_scale_matrix, i, result.uniforms.u_scale_matrix)
  getInstanceAttr(instancedEntity.attributes.a_texture_matrix, i, result.uniforms.u_texture_matrix)
  getInstanceAttr(instancedEntity.attributes.a_color, i, result.uniforms.u_color)

proc `[]=`*(instancedEntity: var InstancedTextEntity, i: int, entity: UncompiledTextEntity) =
  setInstanceAttr(instancedEntity.attributes.a_translate_matrix, i, entity.uniforms.u_translate_matrix)
  setInstanceAttr(instancedEntity.attributes.a_scale_matrix, i, entity.uniforms.u_scale_matrix)
  setInstanceAttr(instancedEntity.attributes.a_texture_matrix, i, entity.uniforms.u_texture_matrix)
  setInstanceAttr(instancedEntity.attributes.a_color, i, entity.uniforms.u_color)

proc `[]=`*(instancedEntity: var UncompiledInstancedTextEntity, i: int, entity: UncompiledTextEntity) =
  setInstanceAttr(instancedEntity.attributes.a_translate_matrix, i, entity.uniforms.u_translate_matrix)
  setInstanceAttr(instancedEntity.attributes.a_scale_matrix, i, entity.uniforms.u_scale_matrix)
  setInstanceAttr(instancedEntity.attributes.a_texture_matrix, i, entity.uniforms.u_texture_matrix)
  setInstanceAttr(instancedEntity.attributes.a_color, i, entity.uniforms.u_color)

proc crop*(entity: var UncompiledTextEntity, bakedChar: BakedChar, x: GLfloat, y: GLfloat) =
  let
    cropX = GLfloat(bakedChar.x0)
    cropY = GLfloat(bakedChar.y0)
    width = GLfloat(bakedChar.x1 - bakedChar.x0)
    height = GLfloat(bakedChar.y1 - bakedChar.y0)
  entity.crop(cropX, cropY, width, height)
  entity.uniforms.u_scale_matrix.scale(width, height)
  entity.uniforms.u_translate_matrix.translate(bakedChar.xoff, bakedChar.yoff)
  entity.uniforms.u_translate_matrix.translate(x, y)
