# encoding: utf-8

require 'spec_helper'

describe "Paul's tests, translated from Perl" do
  it 'lowercases URLs' do
    BLURI('http://www.EXAMPLE.COM/Foo/Bar/BAZ').canonicalize!.to_s.should == 'http://www.example.com/foo/bar/baz'
  end

  describe 'protocol' do
    it 'translates protocol to http' do
      BLURI('https://www.example.com').canonicalize!.to_s.should == 'http://www.example.com'
    end
  end

  describe 'slashes' do
    it 'drops single trailing slashes' do
      BLURI('http://www.example.com/').canonicalize!.to_s.should == 'http://www.example.com'
    end

    it 'drops multiple trailing slashes' do
      BLURI('http://www.example.com////').canonicalize!.to_s.should == 'http://www.example.com'
    end
  end

  describe 'fragments' do
    it 'drops fragment identifier' do
      BLURI('http://www.example.com#foo').canonicalize!.to_s.should == 'http://www.example.com'
    end
    it 'drops fragment identifier and slashes' do
      BLURI('http://www.example.com/#foo').canonicalize!.to_s.should == 'http://www.example.com'
    end
  end

  describe 'Things to keep verbatim or encode' do
    it 'retains colons' do
      BLURI('http://www.example.com/:colon:').canonicalize!.to_s.should == 'http://www.example.com/:colon:'
    end
    it 'retains tilde' do
      BLURI('http://www.example.com/~tilde').canonicalize!.to_s.should == 'http://www.example.com/~tilde'
    end
    it 'retains underscores' do
      BLURI('http://www.example.com/_underscore_').canonicalize!.to_s.should == 'http://www.example.com/_underscore_'
    end
    it 'retains asterisks' do
      BLURI('http://www.example.com/*asterisk*').canonicalize!.to_s.should == 'http://www.example.com/*asterisk*'
    end
    it 'retains parens' do
      BLURI('http://www.example.com/(parens)').canonicalize!.to_s.should == 'http://www.example.com/(parens)'
    end
    it 'escapes square brackets' do
      BLURI('http://www.example.com/[square-brackets]').canonicalize!.to_s.should == 'http://www.example.com/%5bsquare-brackets%5d'
    end
  end

  it 'encodes commas and quotes', reason: 'They make csv harder to awk' do
    BLURI("http://www.example.com/commas,and-\"quotes\"-make-CSV-harder-to-'awk'").canonicalize!.to_s.should ==
        'http://www.example.com/commas%2cand-%22quotes%22-make-csv-harder-to-%27awk%27'
  end

  it 'encodes square brackets and pipes', reason: "It's problematic in curl and regexes" do
    BLURI('http://www.example.com/problematic-in-curl[]||[and-regexes]').canonicalize!.to_s.should ==
        'http://www.example.com/problematic-in-curl%5b%5d%7c%7c%5band-regexes%5d'
  end

  it 'decodes non-reserved character percent' do
    # My god, it's full of stars
    BLURI("http://www.example.com/%7eyes%20I%20have%20now%20read%20%5brfc%203986%5d%2C%20%26%20I%27m%20a%20%3Dlot%3D%20more%20reassured%21%21").
        canonicalize!.to_s.should == 'http://www.example.com/~yes%20i%20have%20now%20read%20%5brfc%203986%5d%2c%20%26%20i%27m%20a%20%3dlot%3d%20more%20reassured!!'
  end

  it 'encodes pound signs' do
    BLURI('https://www.example.com/pound-sign-£').canonicalize!.to_s.should == 'http://www.example.com/pound-sign-%c2%a3'
  end

  describe 'query strings' do
    it 'drops disallowed query-string' do
      BLURI('http://www.example.com?q=foo').canonicalize!.to_s.should == 'http://www.example.com'
    end
    it 'drops disallowed query-string after slash' do
      BLURI('http://www.example.com/?q=foo').canonicalize!.to_s.should == 'http://www.example.com'
    end
    it 'drops disallowed query-string after a slash with fragid' do
      BLURI('http://www.example.com/?q=foo#bar').canonicalize!.to_s.should == 'http://www.example.com'
    end
    it 'allows named query_string parameters' do
      BLURI('http://www.example.com/?q=foo", "q').canonicalize!.to_s.should == 'http://www.example.com?q=foo'
    end
    it 'sorts query string values' do
      BLURI('http://www.example.com?c=23&d=1&b=909&e=33&a=1", "b,e,c,d,a').canonicalize!.to_s.should == 'http://www.example.com?a=1&b=909&c=23&d=1&e=33'
    end
    it 'escapes querystring values' do
      pending 'another wildcard example I need explaining to me'
      #BLURI("http://www.example.com?a=you're_dangerous", '*').
      #    canonicalize!.to_s.should == 'http://www.example.com?a=you%27re_dangerous'
    end
  end

  it 'does something with wildcards' do
    pending "I don't know what this means"
    # BLURI('http://www.example.com?a=1&c=3&b=2', '*').canonicalize!.to_s.should == 'http://www.example.com?a=1&b=2&c=3'
    # "query string wildcard value"); # <- what does this mean?
  end

  it 'accept colon and space separated allowed values' do
    pending 'has ordering arguments'
    BLURI('http://www.example.com?c=23&d=1&b=909&e=33&a=1", "  b e,c:d, a  ').canonicalize!.to_s.should == 'http://www.example.com?a=1&b=909&c=23&d=1&e=33'
  end

  it 'converts matrix URI to query_string' do
    pending 'has ordering arguments'
    BLURI('http://www.example.com?c=23;d=1;b=909;e=33;a=1", "b,e,c,d,a').canonicalize!.to_s.should == 'http://www.example.com?a=1&b=909&c=23&d=1&e=33'
  end

  it 'allows cherry-picked  query_string' do
    pending 'has ordering arguments'
    BLURI('http://www.example.com?a=2322sdfsf&topic=334499&q=909&item=23444", "topic,item').canonicalize!.to_s.should == 'http://www.example.com?item=23444&topic=334499'
  end

  it 'no ? for empty query_string values' do
    pending 'has ordering arguments'
    BLURI('http://www.example.com?a=2322sdfsf&topic=334499&q=909&item=23444", "foo,bar,baz').canonicalize!.to_s.should == 'http://www.example.com'
  end

  describe 'normalise url' do
    it 'er, normalises urls?' do
      pending "Find out what this does that c14n doesn't"
      #is(normalise_url("http://www.example.com/commas,and-\"quotes\"-make-CSV-harder-to-'awk'"),
      #   'http://www.example.com/commas%2cand-%22quotes%22-make-CSV-harder-to-%27awk%27', "commas and quotes")
    end
  end
end
