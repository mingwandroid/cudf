/*
 * Copyright (c) 2019, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <tests/utilities/column_wrapper.hpp>

#include <cudf/search.hpp>
#include <cudf/sorting.hpp>
#include <cudf/types.hpp>

#include <benchmark/benchmark.h>

#include <random>

#include <benchmarks/fixture/benchmark_fixture.hpp>
#include <benchmarks/synchronization/synchronization.hpp>
#include <tests/utilities/base_fixture.hpp>

// #include <gperftools/profiler.h>

class Search : public cudf::benchmark {
};

void BM_non_null_column(benchmark::State& state)
{
  const cudf::size_type column_size{(cudf::size_type)state.range(0)};
  const cudf::size_type values_size = column_size;

  auto col_data_it = cudf::test::make_counting_transform_iterator(
    0, [=](cudf::size_type row) { return static_cast<float>(row); });
  auto val_data_it = cudf::test::make_counting_transform_iterator(
    0, [=](cudf::size_type row) { return static_cast<float>(values_size - row); });

  cudf::test::fixed_width_column_wrapper<float> column(col_data_it, col_data_it + column_size);
  cudf::test::fixed_width_column_wrapper<float> values(val_data_it, val_data_it + values_size);

  // ProfilerStart("search_new.prof");
  for (auto _ : state) {
    cuda_event_timer timer(state, true);
    auto col = cudf::experimental::upper_bound(cudf::table_view({column}),
                                               cudf::table_view({values}),
                                               {cudf::order::ASCENDING},
                                               {cudf::null_order::BEFORE});
  }
  // ProfilerStop();
}

BENCHMARK_DEFINE_F(Search, AllValidColumn)(::benchmark::State& state) { BM_non_null_column(state); }

BENCHMARK_REGISTER_F(Search, AllValidColumn)
  ->UseManualTime()
  ->Unit(benchmark::kMillisecond)
  ->Arg(400000000);

auto make_validity_iter()
{
  static constexpr int r_min = 1;
  static constexpr int r_max = 10;

  cudf::test::UniformRandomGenerator<uint8_t> rand_gen(r_min, r_max);
  uint8_t mod_base = rand_gen.generate();
  return cudf::test::make_counting_transform_iterator(
    0, [mod_base](auto row) { return (row % mod_base) > 0; });
}

void BM_nullable_column(benchmark::State& state)
{
  const cudf::size_type column_size{(cudf::size_type)state.range(0)};
  const cudf::size_type values_size = column_size;

  auto col_data_it = cudf::test::make_counting_transform_iterator(
    0, [=](cudf::size_type row) { return static_cast<float>(row); });
  auto val_data_it = cudf::test::make_counting_transform_iterator(
    0, [=](cudf::size_type row) { return static_cast<float>(values_size - row); });

  cudf::test::fixed_width_column_wrapper<float> column(
    col_data_it, col_data_it + column_size, make_validity_iter());
  cudf::test::fixed_width_column_wrapper<float> values(
    val_data_it, val_data_it + values_size, make_validity_iter());

  auto sorted = cudf::experimental::sort(cudf::table_view({column}));

  for (auto _ : state) {
    cuda_event_timer timer(state, true);
    auto col = cudf::experimental::upper_bound(sorted->view(),
                                               cudf::table_view({values}),
                                               {cudf::order::ASCENDING},
                                               {cudf::null_order::BEFORE});
  }
}

BENCHMARK_DEFINE_F(Search, NullableColumn)(::benchmark::State& state) { BM_nullable_column(state); }

BENCHMARK_REGISTER_F(Search, NullableColumn)
  ->UseManualTime()
  ->Unit(benchmark::kMillisecond)
  ->Arg(100000000);

void BM_table(benchmark::State& state)
{
  using wrapper = cudf::test::fixed_width_column_wrapper<float>;

  const cudf::size_type num_columns{(cudf::size_type)state.range(0)};
  const cudf::size_type column_size{(cudf::size_type)state.range(1)};
  const cudf::size_type values_size = column_size;

  std::vector<wrapper> columns;
  std::vector<wrapper> values;

  auto make_table = [&](std::vector<wrapper>& cols, cudf::size_type col_size) {
    cudf::test::UniformRandomGenerator<int> random_gen(0, 100);
    auto data_it = cudf::test::make_counting_transform_iterator(
      0, [&](cudf::size_type row) { return random_gen.generate(); });
    auto valid_it = cudf::test::make_counting_transform_iterator(
      0, [&](cudf::size_type row) { return random_gen.generate() < 90; });

    for (cudf::size_type i = 0; i < num_columns; i++) {
      cols.emplace_back(data_it, data_it + col_size, valid_it);
    }

    std::vector<cudf::column_view> col_views;
    std::transform(
      cols.begin(), cols.end(), std::back_inserter(col_views), [](wrapper& c) -> cudf::column_view {
        return c;
      });

    return cudf::table_view{col_views};
  };

  auto data_table   = make_table(columns, column_size);
  auto values_table = make_table(values, values_size);

  std::vector<cudf::order> orders(num_columns, cudf::order::ASCENDING);
  std::vector<cudf::null_order> null_orders(num_columns, cudf::null_order::BEFORE);
  auto sorted = cudf::experimental::sort(data_table);

  for (auto _ : state) {
    cuda_event_timer timer(state, true);
    auto col = cudf::experimental::lower_bound(sorted->view(), values_table, orders, null_orders);
  }
}

BENCHMARK_DEFINE_F(Search, Table)(::benchmark::State& state) { BM_table(state); }

static void CustomArguments(benchmark::internal::Benchmark* b)
{
  for (int num_cols = 1; num_cols <= 10; num_cols *= 2)
    for (int col_size = 1000; col_size <= 100000000; col_size *= 10) b->Args({num_cols, col_size});
}

BENCHMARK_REGISTER_F(Search, Table)
  ->UseManualTime()
  ->Unit(benchmark::kMillisecond)
  ->Apply(CustomArguments);
