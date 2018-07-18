# # frozen_string_literal: true
#
# FFMPEG::EncodingOptions.class_eval do
#   private
#
#   def convert_x264_vprofile_level(value)
#     ['-level', value]
#   end
#
#   def convert_constant_rate_factor(value)
#     ['-crf', value]
#   end
#
#   def convert_reference_frames(value)
#     ['-refs', value]
#   end
#
#   def convert_strict(value)
#     value ? %w[-strict -2] : []
#   end
#
#   def convert_custom(value)
#     [value]
#   end
# end
