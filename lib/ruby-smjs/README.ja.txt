=begin
=Ruby/SpiderMonkey
-------------------------------------------------
nazoking@gmail.com
http://nazo.yi.org/rubysmjs/
-------------------------------------------------

Ruby �� JavaScript ��Ȥ�����Υ⥸�塼��Ǥ���

���ߥ���ե��С������Ǥ���
���饹̾���᥽�å�̾�ʤɤ��ѹ�������ǽ��������ޤ���

==
�����Х����ɤ�JavaScript���Ȥ���ȿ�������������


==���󥹥ȡ���
 ruby extconf.rb
 make
 make install

�����������ߤޤ�����ե��С������ʤΤǡ����󥹥ȡ��뤷�ʤ����������Ǥ��礦��
Debian/sarge �ʳ��Ǿ�꤯ư������Ϥ����󤯤�������
 Debian/sid , FreeBSD6/ppc �Ǥ�ư�����Ȥ������

��꤯ư��ʤ����ϡ���꤯ư���褦�ˤ��Ƥ���������

test.rb �ϥƥ��ȥ����ɤǤ���

 ruby test.rb

�Ǽ¹Ԥ��ޤ����̤�ʤ��ƥ��Ȥ����äƤⵤ�ˤ��ʤ���
�ʤ��뤤�ϡ��ƥ��Ȥ��̤�褦�˽������ƥѥå��� nazoking@gmail.com �ޤǡ�


==����ˡ

require "spidermonkey"

make install ���Ƥ��ʤ����ϡ�require "./spidermonkey" �ʤɤȡ�spidermonkey.so �ξ���ѥ��դ��ǻ��ꤷ�ޤ��礦��

SpiderMonkey::evalget("1").to_ruby #=> 1

�Τ褦�ˤǤ��ޤ���


=== JavaScript���鸫��Ruby���֥�������

��Ruby���֥������� rbobj �� Context::set_property( "name", rbobj )�� JavaScript �� name �Ȥ����Ϥ����Ȥ��Ǥ��ޤ���Ruby�����Ϥ��줿���֥������Ȥϡ��б�����JavaScript�ץ�ߥƥ����ͤ������硢�����ͤ��Ѵ�����ޤ����ʤ�����Ruby���֥������Ȥ��åפ���JavaScript���֥������Ȥˤʤ�ޤ���

��Ruby�Ǥϡ����֥������ȤΥץ�ѥƥ����Ȥ�����ǰ���ʤ������֥������Ȥ��Ф��ƥ��������Ǥ�����ʤϥ᥽�åɤΤߤǤ����ޤ���JavaScript�ˤϤʤ���ǰ�Ȥ��ơ�����Ȥ���������ѿ�������ޤ���Ruby/SpiderMonkey�Ǥϡ�Ruby���֥������Ȥ��åפ���ݤˡ����Τ褦�˥᥽�åɤȥץ�ѥƥ��������ꤵ��Ƥ����ΤȤ��ƿ����񤤤ޤ���

* Ruby������������ץ�ѥƥ���
* Ruby�Υ᥽�åɤ��⡢������0�ĸ���Τ�Ρ������ץ�ѥƥ���
* Ruby�Υ᥽�åɤ��⡢���������Ѥ��뤤�ϰ�İʾ�Τ�Ρ������᥽�å�

������ˡ���������ϲ��Ѱ������Ĥ���ʣ���Υ᥽�åɤΰ������狼��ˤ������ȤǤ�������¾����ˡ���פ��Ĥ��ʤ��ä��Τǡ����������ʤäƤ��ޤ���


==��ե����

SpiderMonkey �Ǥϡ���󥿥�������������󥿥����ǥ���ƥ����Ȥ�����������Υ���ƥ����Ȥ��Ф��ƥ�����ץȤ�¹Ԥ��ޤ���
������֤������뤿�ᡢ��󥿥���ϥ⥸�塼�뤬���ɤ��줿�����Ǻ�������ޤ����ޤ���default_context �Ȥ�������ƥ����Ȥ��Ѱդ���SpiderMonkey���饹���֥������Ȥ��Ф��ƥ�å��������ꤲ����������᥽�åɤ� SpiderMonkey���饹���֥������Ȥˤʤ���硢�ǥե���ȥ���ƥ����Ȥ˰Ѿ�����ޤ���

Ʊ���� Context���֥������ȤΥ᥽�åɤ⡢���������Τ��ʤ���硢global���֥������Ȥ˰Ѿ�����ޤ���

=== SpiderMonkey

:SpiderMonkey::LIB_VERSION
  SpiderMonkey�ΥС������ʸ������֤�ޤ�

:SpiderMonkey::eval( code )
  �ǥե���ȥ���ƥ����Ⱦ�� javascript-code ��eval���ޤ���
  ��̤� SpiderMonkey::Value ���֤�ޤ���

:SpiderMonkey::evaluate( code )
  �ǥե���ȥ���ƥ����Ⱦ�� javascript-code ��eval���ޤ���
  ��̤� Ruby���֥������� ���֤�ޤ���
    SpiderMonkey::evalate( code ).to_ruby
  ��Ʊ�դǤ�

=== SpiderMonkey::Context
����ƥ����Ⱦ���Υ�åѡ����饹�Ǥ���

:SpiderMonkey::Context.new( stack_size=8192 )
  ����������ƥ����Ȥ�������ޤ���

:SpiderMonkey::Context#eval( code )
  Javascript������ code �򡢥���ƥ����Ⱦ�Ǽ¹Ԥ��ޤ���
  ��̤��ץ�ߥƥ����ͤξ�硢�б�����Ruby�Υ��֥������Ȥ��֤�ޤ���
  ��̤����֥������Ȥ� SpiderMonkey::Value ���֤�ޤ���
  ��̤� Ruby �����Ϥ��줿���֥������ȤǤ��ä���硢����Ruby���֥������Ȥ��֤�ޤ���

:SpiderMonkey::Context#eval( code )
  Javascript������ code �򡢥���ƥ����Ⱦ�Ǽ¹Ԥ��ޤ���
  ��̤� SpiderMonkey::Value ���֤�ޤ���

:SpiderMonkey::Context#evaluate( code )
  Javascript������ code �򡢥���ƥ����Ⱦ�Ǽ¹Ԥ��ޤ���
  ��̤� Ruby���֥������Ȥ��֤�ޤ���
    SpiderMonkey::Context#evalget( code ).to_ruby
  ��Ʊ�դǤ�

:SpiderMonkey::Context#version
  Context��JavaScript�ΥС�������ʸ������֤��ޤ���

:SpiderMonkey::Context#version=
  Context��JavaScript�ΥС�������ʸ��������ꤷ�ޤ���
  ����Ǥ��ʤ��С������ξ��� SpiderMonkey::Error ��ȯ�����ޤ���

:SpiderMonkey::Context#gc()
  ���٥졼�����쥯������ȯ�������ޤ�����˥ǥХå���

:SpiderMonkey::Context#running?
  eval �¹���ʤ�true���֤��ޤ���������Хå��ؿ����ruby���ƤФ줿�ʤ� true�ˤʤ�ޤ���

:SpiderMonkey::Context#global
  global���֥������Ȥ�SpiderMonkey::Value��åѡ����֤��ޤ���

=== SpiderMonkey::Value
  JavaScript���֥������Ȥ�Ruby��åѡ��Ǥ���
  JavaScript�����Ϥ�����ͤϡ��ץ�ߥƥ����Ͱʳ��Ϥ��Υ��饹�˥�åפ���ޤ���

:SpiderMonkey::Value#to_ruby
  Ŭ����Ruby���֥������Ȥ��Ѵ������֤��ޤ���
  undefined ����� null �� nil ���Ѵ�����ޤ���
  Object��Hash�ˡ�Array��Array���Ѵ�����ޤ���
  Object��Array�λҡʥץ�ѥƥ����ˤ�ޤ���Ѵ����ޤ���
  function����function����ޤ�Object���Ѵ����褦�Ȥ���� ConvertError ��ȯ�����ޤ���
  Ruby�����Ϥ���Ƥ������֥������Ȥϸ���Ruby���֥������Ȥˤʤ�ޤ���
  JavaScript���Array�˸��̤Υץ�ѥƥ��������ꤷ�Ƥ⡢�����ͤ��Ѵ�����ޤ���

:SpiderMonkey::Value#to_a
  Ruby�� Array �ˤ����֤��ޤ���
  JavaScript �� Array�ʳ��Τ�Τ�Ŭ���ʥ��֥������Ȥˤ������ to_a �᥽�åɤ�ƤӽФ��ޤ���
  JavaScript���Array�˸��̤Υץ�ѥƥ��������ꤷ�Ƥ⡢�����ͤ��Ѵ�����ޤ���
  JavaScript�δؿ����Ѵ��Ǥ��ޤ��󡣡�SpiderMonkey::ConvertError ��������ޤ���

:SpiderMonkey::Value#to_i
  Ruby�� Integer �ˤ����֤��ޤ���

:SpiderMonkey::Value#to_f
  Ruby�� Float �ˤ����֤��ޤ���

:SpiderMonkey::Value#to_num
  Ruby�� Integer �ޤ��� Float �ˤ����֤��ޤ���

:SpiderMonkey::Value#to_h
  Ruby�� Hash�ˤ����֤��ޤ���
  ���֥������Ȱʳ����㳰���֤��ޤ���
  �ؿ���ޤ४�֥������Ȥ��Ѵ��Ǥ��ޤ���

:SpiderMonkey::Value#to_bool
  true �ޤ��� false ���֤�ޤ���JavaScript�����Ѵ������Τǡ���ʸ����0�ʤɤ�false �ˤʤ�ޤ���

:SpiderMonkey::Value#typeof
  typeof x ��JavaScript��ǹԤ������η�̤�ʸ������֤��ޤ���

:SpiderMonkey::Value#function( name , &proc )
  JavaScript���֥������Ȥ� name �Ȥ���̾���Ǵؿ���������ޤ���
  ���δؿ����ƤФ��ȡ�proc ���¹Ԥ���ޤ�

:SpiderMonkey::Value#call( name , args... )
  JavaScript���֥������Ȥδؿ���ƤӽФ��ޤ���
  args �������ˤʤ�ޤ���
  ���ͤ� SpiderMonkey::Value �Ǥ�

:SpiderMonkey::Value#set_property( name, value )
  JavaScript���֥������Ȥ� name �Ȥ���̾���ǥץ�ѥƥ�����������ޤ���

:SpiderMonkey::Value#get_property( name )
  JavaScript���֥������Ȥ� name �Ȥ���̾���Υץ�ѥƥ�����������ޤ���
  SpiderMonkey::Value ���֥������Ȥ��֤�ޤ���

=end

