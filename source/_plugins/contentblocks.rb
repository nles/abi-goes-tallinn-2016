# Plugin: jekyll-contentblocks
# Author: Rusty Geldmacher
# Git: https://github.com/rustygeldmacher/jekyll-contentblocks
# Instructions: https://github.com/rustygeldmacher/jekyll-contentblocks#usage
module Jekyll
  module ContentBlocks
    VERSION = "0.0.3"
    module Common
      def look_up(context, name)
        lookup = context
        name.split(".").each do |value|
          lookup = lookup[value]
        end
        lookup
      end

      def get_content_block_name(tag_name, block_name)
        block_name = (block_name || '').strip
        if block_name == ''
          raise SyntaxError.new("No block name given in #{tag_name} tag")
        end
        block_name
      end

      def content_for_block(context)
        context.environments.first['contentblocks'] ||= {}
        context.environments.first['contentblocks'][@block_name] ||= []
      end
    end
  end
  module Convertible
    alias_method :do_layout_orig, :do_layout

    def do_layout(payload, layouts)
      payload['converters'] = converters_for_content_block
      payload['contentblocks'] = {}
      do_layout_orig(payload, layouts)
    end

    private

    def converters_for_content_block
      if jekyll_version_less_than?('2.3.0')
        [converter]
      else
        converters.reject do |converter|
          converter.class == Jekyll::Converters::Identity
        end
      end
    end

    def jekyll_version_less_than?(version)
      Gem::Version.new(Jekyll::VERSION) < Gem::Version.new(version)
    end
  end
  module Tags
    class ContentFor < Liquid::Block
      include ::Jekyll::ContentBlocks::Common
      alias_method :render_block, :render

      def initialize(tag_name, block_name, tokens)
        super
        @block_name = get_content_block_name(tag_name, block_name)
      end

      def render(context)
        content_for_block(context) << render_block(context)
        ''
      end
    end
    class ContentBlock < Liquid::Tag
      include ::Jekyll::ContentBlocks::Common

      def initialize(tag_name, block_name_raw, tokens)
        super
        @tag_name = tag_name
        @block_name_raw = block_name_raw
      end

      def render(context)
        if @block_name_raw[0] == "["
          block_name_parsed = look_up(context,@block_name_raw[1..-2])
        else
          block_name_parsed = @block_name_raw
        end
        @block_name = get_content_block_name(@tag_name, block_name_parsed)
        block_content = content_for_block(context).join
        converters = context.environments.first['converters']
        converters.reduce(block_content) do |content, converter|
          converter.convert(content)
        end
      end
    end
  end
end

Liquid::Template.register_tag('contentfor', Jekyll::Tags::ContentFor)
Liquid::Template.register_tag('contentblock', Jekyll::Tags::ContentBlock)
