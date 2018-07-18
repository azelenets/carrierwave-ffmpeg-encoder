# frozen_string_literal: true

require 'streamio-ffmpeg'
require 'carrierwave'
require 'carrierwave/ffmpeg_encoder/options'
require 'carrierwave/ffmpeg_encoder/theora'

module CarrierWave
  module FfmpegEncoder
    extend ActiveSupport::Concern

    def self.ffmpeg2theora_binary=(bin)
      @ffmpeg2theora = bin
    end

    def self.ffmpeg2theora_binary
      @ffmpeg2theora.nil? ? 'ffmpeg2theora' : @ffmpeg2theora
    end

    module ClassMethods
      def encode_audio(target_format, options={})
        process encode_audio: [target_format, options]
      end

      def encode_video(target_format, options={})
        if target_format.to_sym == :ogv
          process encode_ogv: [options]
        else
          process encode_video: [target_format, options]
        end
      end
    end

    def encode_ogv(opts)
      cache_stored_file! unless cached?

      tmp_path  = File.join(File.dirname(current_path), 'tmpfile.ogv')
      @options = CarrierWave::FfmpegEncoder::Options.new(:ogv, opts)

      with_trancoding_callbacks do
        transcoder = CarrierWave::FfmpegEncoder::Theora.new(current_path, tmp_path)
        transcoder.run(@options.logger(model))
        File.rename(tmp_path, current_path)
      end
    end

    def encode_audio(format, opts={})
      cache_stored_file! unless cached?

      @options = CarrierWave::FfmpegEncoder::Options.new(format, opts)
      tmp_path = File.join(File.dirname(current_path), "tmpfile.#{format}")
      file = ::FFMPEG::Movie.new(current_path)

      yield(file, @options.format_options) if block_given?
      progress = @options.progress(model)

      with_trancoding_callbacks do
        if progress
          file.transcode(tmp_path, @options.format_params) do
            |value| progress.call(value)
          end
        else
          file.transcode(tmp_path, @options.format_params)
        end
        File.rename tmp_path, current_path
      end
    end

    def encode_video(format, opts={})
      cache_stored_file! unless cached?

      @options = CarrierWave::FfmpegEncoder::Options.new(format, opts)
      tmp_path = File.join(File.dirname(current_path), "tmpfile.#{format}")
      file = ::FFMPEG::Movie.new(current_path)

      if opts[:resolution] == :same
        @options.format_options[:resolution] = file.resolution
      end

      if opts[:video_bitrate] == :same
        @options.format_options[:video_bitrate] = file.video_bitrate
      end

      yield(file, @options.format_options) if block_given?

      progress = @options.progress(model)

      with_trancoding_callbacks do
        if progress
          file.transcode(tmp_path, @options.format_params, @options.encoder_options) {
            |value| progress.call(value)
          }
        else
          file.transcode(tmp_path, @options.format_params, @options.encoder_options)
        end
        File.rename tmp_path, current_path
      end
    end

    private

    def with_trancoding_callbacks(&block)
      callbacks = @options.callbacks
      logger = @options.logger(model)

      begin
        send_callback(callbacks[:before_transcode])
        setup_logger
        block.call
        send_callback(callbacks[:after_transcode])
      rescue => e
        send_callback(callbacks[:rescue])

        if logger
          logger.error "#{e.class}: #{e.message}"
          e.backtrace.each do |b|
            logger.error b
          end
        end

        raise CarrierWave::ProcessingError.new("Failed to transcode with FFmpeg. Check ffmpeg install and verify file is not corrupt or cut short. Original error: #{e}")
      ensure
        reset_logger
        send_callback(callbacks[:ensure])
      end
    end

    def send_callback(callback)
      model.send(callback, @options.format, @options.raw) if callback.present?
    end

    def setup_logger
      return unless @options.logger(model).present?
      @ffmpeg_logger = ::FFMPEG.logger
      ::FFMPEG.logger = @options.logger(model)
    end

    def reset_logger
      return unless @ffmpeg_logger
      ::FFMPEG.logger = @ffmpeg_logger
    end
  end
end
