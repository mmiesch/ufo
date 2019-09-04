/*
 * (C) Copyright 2019 UCAR
 *
 * This software is licensed under the terms of the Apache Licence Version 2.0
 * which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
 */

#ifndef UFO_FILTERS_OBSFUNCTIONS_OBSFUNCTIONSCATTERING_H_
#define UFO_FILTERS_OBSFUNCTIONS_OBSFUNCTIONSCATTERING_H_

#include "ufo/filters/ObsFilterData.h"
#include "ufo/filters/obsfunctions/ObsFunctionBase.h"

namespace oops {
  class Variables;
}

namespace ufo {

// -----------------------------------------------------------------------------

class ObsFunctionScattering : public ObsFunctionBase {
 public:
  ObsFunctionScattering();
  ~ObsFunctionScattering();

  void compute(const ObsFilterData &,
               ioda::ObsDataVector<float> &) const;
  const oops::Variables & requiredGeoVaLs() const;
 private:
  oops::Variables geovars_;
};

// -----------------------------------------------------------------------------

}  // namespace ufo

#endif  // UFO_FILTERS_OBSFUNCTIONS_OBSFUNCTIONSCATTERING_H_
