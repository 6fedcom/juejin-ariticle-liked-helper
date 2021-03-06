import { SpinProps } from 'antd/es/spin'
import { History } from 'history'
export interface Article {
  title: string
  author: string
  type: string
  tags: any[]
  collectionCount: number
  viewsCount: number
  createdAt: string
  description: string
  filteredValue: Object | undefined
  articleId: any
}

export interface State {
  likeList: any[]
  pagination: any
  searchText: string
  searchedColumn: string
  loading: boolean | SpinProps | undefined
  scroll: undefined | number
  isPc: boolean
  visible: boolean
}
interface SearchFunc {
  (value: any[]): any[]
}
export interface filterDropdownType {
  setSelectedKeys: SearchFunc
  selectedKeys: string
  confirm: () => void
  clearFilters: unknown
}

export interface Props {
  id?: string
  history?: History
}

export interface MyWindow extends Window {
  polyvPlayer: any
}
