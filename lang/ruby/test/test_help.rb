# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rubygems'
require 'test/unit'
require 'avro'
require 'stringio'

require 'fileutils'
FileUtils.mkdir_p('tmp')

class RandomData
  def initialize(schm, seed=nil)
    srand(seed) if seed
    @seed = seed
    @schm = schm
  end

  def next
    nextdata(@schm)
  end

  def nextdata(schm, d=0)
    case schm.type
    when 'boolean'
      rand > 0.5
    when 'string'
      randstr()
    when 'int'
      rand(Avro::Schema::INT_MAX_VALUE - Avro::Schema::INT_MIN_VALUE) + Avro::Schema::INT_MIN_VALUE
    when 'long'
      rand(Avro::Schema::LONG_MAX_VALUE - Avro::Schema::LONG_MIN_VALUE) + Avro::Schema::LONG_MIN_VALUE
    when 'float'
      (-1024 + 2048 * rand).round.to_f
    when 'double'
      Avro::Schema::LONG_MIN_VALUE + (Avro::Schema::LONG_MAX_VALUE - Avro::Schema::LONG_MIN_VALUE) * rand
    when 'bytes'
      randstr(BYTEPOOL)
    when 'null'
      nil
    when 'array'
      arr = []
      len = rand(5) + 2 - d
      len = 0 if len < 0
      len.times{ arr << nextdata(schm.items, d+1) }
      arr
    when 'map'
      map = {}
      len = rand(5) + 2 - d
      len = 0 if len < 0
      len.times do
        map[nextdata(Avro::Schema::PrimitiveSchema.new('string'))] = nextdata(schm.values, d+1)
      end
      map
    when 'record'
      m = {}
      schm.fields.each do |field|
        m[field.name] = nextdata(field.type, d+1)
      end
      m
    when 'union'
      types = schm.schemas
      nextdata(types[rand(types.size)], d)
    when 'enum'
      symbols = schm.symbols
      len = symbols.size
      return nil if len == 0
      symbols[rand(len)]
    when 'fixed'
      BYTEPOOL[rand(BYTEPOOL.size), 1]
    end
  end

  CHARPOOL = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  BYTEPOOL = '12345abcd'

  def randstr(chars=CHARPOOL, length=20)
    str = ''
    rand(length+1).times { str << chars[rand(chars.size)] }
    str
  end
end