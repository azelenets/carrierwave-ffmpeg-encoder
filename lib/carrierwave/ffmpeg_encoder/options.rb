# frozen_string_literal: true

module CarrierWave
  module FfmpegEncoder
    class Options
      DEFAULTS_MP3 = { audio_codec: 'libmp3lame',
                       audio_bitrate: '160k',
                       audio_sample_rate: '44100',
                       audio_channels: '2',
                       threads: '2' }

      DEFAULTS_MP4 = { resolution: :same,
                       video_codec: 'libx264',
                       # reference_frames: '4',
                       # constant_rate_factor: '30',
                       frame_rate: '25',
                       x264_vprofile: 'baseline',
                       # x264_vprofile_level: '3',
                       audio_codec: 'aac',
                       audio_bitrate: '64k',
                       audio_sample_rate: '44100',
                       audio_channels: '1',
                       # strict: true,
                       threads: '2' }.freeze

      DEFAULTS_OGV = { resolution: '640x360',
                       watermark: {},
                       video_codec: 'libtheora',
                       audio_codec: 'libvorbis',
                       threads: '2' }.freeze

      DEFAULTS_WEBM = { resolution: '640x360',
                        watermark: {},
                        video_codec: 'libvpx',
                        audio_codec: 'libvorbis',
                        threads: '2' }.freeze

      attr_reader :format, :custom, :callbacks

      def initialize(format, options)
        @format = format.to_s
        @custom = options[:custom]
        @callbacks = options[:callbacks] || {}
        @logger = options[:logger]
        @unparsed = options
        @progress = options[:progress]
        @format_options = defaults.merge(options)
      end

      def raw
        @unparsed
      end

      def logger(model)
        model.send(@logger) if @logger.present?
      end

      def progress(model)
        if @progress
          args = model.method(@progress).arity == 3 ? [@format, @format_options] : []
          lambda { |val| model.send(@progress, *(args + [val])) }
        end
      end

      def encoder_options
        { }
      end

      # input
      def format_options
        @format_options
      end

      # output
      def format_params
        params = @format_options.dup
        params.delete(:watermark)
        if watermark?
          params[:custom] = [params[:custom], watermark_params].compact.join(' ')
        end
        params
      end

      def watermark?
        @format_options[:watermark].present?
      end

      def watermark_params
        return nil unless watermark?

        @watermark_params ||= begin
          path = @format_options[:watermark][:path]
          position = @format_options[:watermark][:position].to_s || :bottom_right
          margin = @format_options[:watermark][:pixels_from_edge] || @format_options[:watermark][:margin] || 10
          positioning = case position
                        when 'bottom_left'
                          "#{margin}:main_h-overlay_h-#{margin}"
                        when 'bottom_right'
                          "main_w-overlay_w-#{margin}:main_h-overlay_h-#{margin}"
                        when 'top_left'
                          "#{margin}:#{margin}"
                        when 'top_right'
                          "main_w-overlay_w-#{margin}:#{margin}"
                        end

          "-vf \"movie=#{path} [logo]; [in][logo] overlay=#{positioning} [out]\""
        end
      end

      private

      def defaults
        @defaults ||= case format
                      when 'mp3'  then DEFAULTS_MP3
                      when 'mp4' then DEFAULTS_MP4
                      when 'ogv' then DEFAULTS_OGV
                      when 'webm' then DEFAULTS_WEBM
                      end
      end
    end
  end
end
