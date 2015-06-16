# encoding: UTF-8

module Sip
  module Basica
    extend ActiveSupport::Concern

    included do
      scope :habilitados, -> (campoord = "nombre") {
        where(fechadeshabilitacion: nil).order(campoord.to_sym)
      }
      validates :nombre, presence: true, allow_blank: false, 
        length: { maximum: 500 } 
      validates :observaciones, length: { maximum: 5000 }
      validates :fechacreacion, presence: true, allow_blank: false

      # Si atr corresponde a tabla combinada la retorna
      # en otro caso retorna nil
      def asociacion_combinada(atr)
        if atr.is_a?(Hash) && atr.first[0].to_s.ends_with?("_ids")
          na = atr.first[0].to_s.chomp("_ids")
          a = self.class.reflect_on_all_associations
          r = a.select { |ua| ua.name.to_s == na }[0] 
          return r
        end
        return nil
      end

      # Si atr es llave foranea retorna asociación a este modelo
      # en otro caso retorna nil
      def asociacion_llave_foranea(atr)
        aso = self.class.reflect_on_all_associations
        bel = aso.select { |a| a.macro == :belongs_to } 
        fk = bel.map(&:foreign_key)
        if fk.include? atr
          r = aso.select { |a| a.foreign_key == atr }[0] 
          return r
        end
        return nil
      end

      # Si atr es atributo que es llave foranea retorna su clase
      # si no retorna nil
      def clase_llave_foranea(atr)
        r = asociacion_llave_foranea(atr)
        if r
          return r.class_name.constantize
        end
        return nil
      end

      # Presentar nombre del registro en index y show
      def presenta_nombre
        self['nombre']
      end

      # Presentar campo atr del registro en index y show genérico (no sobrec)
      def presenta_gen(atr)
        clf = clase_llave_foranea(atr)
        if self.class.columns_hash && self.class.columns_hash[atr] && 
          self.class.columns_hash[atr].type == :boolean 
          self[atr] ? "Si" : "No" 
        elsif asociacion_combinada(atr)
          ac = asociacion_combinada(atr).name.to_s
          e = self.send(ac)
          e.inject("") { |memo, i| 
            (memo == "" ? "" : memo + "; ") + i.presenta_nombre 
          }
        elsif clf
          if (self[atr.to_s])
            clf.find(self[atr.to_s]).presenta_nombre
          else
            ""
          end
        else
          self[atr.to_s].to_s
        end
      end

      # Presentar campo atr del registro en index y show para sobrecargar
      def presenta(atr)
        presenta_gen(atr)
      end

      # Para búsquedas tipo autocompletacion en base de datos campos a observar
      def self.busca_etiqueta_campos
        ['nombre']
      end

      # Para búsquedas tipo autocompletacion etiqueta que se retorna
      def busca_etiqueta
        v = self.class.busca_etiqueta_campos.map { |c|
          self[c]
        }
        return v.join(" ")
      end

      # Para búsquedas tipo autocompletacion valor que se retorna
      def busca_valor
        self['id']
      end

    end


  end
end
