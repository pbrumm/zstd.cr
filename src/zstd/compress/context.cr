require "../context"
require "../compress"

# Usage:
# ```
# cctx = Zstd::Compress::Context.new
# buf = Bytes.new 22
# cbuf = cctx.compress buf
# ```
class Zstd::Compress::Context < Zstd::Context
  class Error < Zstd::Context::Error
  end

  def initialize(level : Int32 = LEVEL_DEFAULT)
    @ptr = Lib.create_c_ctx
    raise Error.new("NULL ptr create_c_ctx") if !@ptr || @ptr.null?

    self.level = level
  end

  def compress(src : Bytes, dst : Bytes = Bytes.new(compress_bound(src.bytesize))) : Bytes
    r = Lib.compress2 @ptr, dst, dst.bytesize, src, src.bytesize
    Error.raise_if_error r, "compress_c_ctx"
    dst[0, r]
  end

  # TODO: maybe more parameters.
  # ZSTD_c_dictIDFlag
  # ZSTD_c_rsyncable experimental
  {% for name, param in {"level" => "ZstdCCompressionLevel", "threads" => "ZstdCNbWorkers"} %}
		def {{name.id}}
			get_param Lib::ZstdCParameter::{{param.id}}
		end

		def {{name.id}}=(val)
			set_param Lib::ZstdCParameter::{{param.id}}, val
		end
	{% end %}

  {% for name, param in {"checksum_flag" => "ZstdCChecksumFlag"} %}
		private def {{name.id}}
			get_param Lib::ZstdCParameter::{{param.id}}
		end

		private def {{name.id}}=(val)
			set_param Lib::ZstdCParameter::{{param.id}}, val
		end
	{% end %}

  def checksum
    checksum_flag.to_i != 0
  end

  def checksum=(value : Bool)
    self.checksum_flag = value ? 1 : 0
    value
  end

  # Maximum output buffer size for compression
  def compress_bound(size)
    r = Lib.compress_bound size
    Error.raise_if_error r, "compress_bound"
    r
  end

  private def get_param(key)
    r = Lib.c_ctx_get_parameter @ptr, key, out val
    Error.raise_if_error r, "c_ctx_get_parameter"
    val
  end

  private def set_param(key, val)
    r = Lib.c_ctx_set_parameter @ptr, key, val
    Error.raise_if_error r, "c_ctx_set_parameter"
    val
  end

  # :nodoc:
  def to_unsafe
    @ptr
  end

  def free!
    Lib.free_c_ctx @ptr
  end
end
